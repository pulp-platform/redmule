#!/usr/bin/env python3
# Copyright 2020 ETH Zurich and University of Bologna
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#

# Run shell commands listed in a file separated by newlines in a parallel
# fashion. If requested the results (tuples consisting of command, stdout,
# stderr and returncode) will be gathered in a junit.xml file. There a few
# knobs to tune the number of spawned processes and the junit.xml formatting.

# Author: Robert Balas (balasr@iis.ee.ethz.ch)

# Vendored from https://github.com/pulp-platform/neureka/blob/main/regr/bwruntests.py
# for use in RedMulE's regression infrastructure, with two fixes to fork():
#  1. commands are now kept as a single string (instead of shlex.split into a
#     list), since Popen(<list>, shell=True) only runs list[0] as the shell
#     command and silently drops the rest of the words;
#  2. the shell= kwarg is now actually forwarded to Popen() -- previously it
#     was accepted as a named parameter but never passed through, so
#     Popen() always used its shell=False default.

import argparse
import re
from subprocess import (Popen, TimeoutExpired,
                        CalledProcessError, PIPE)
from threading import Lock
import sys
import signal
import os
import multiprocessing
import errno
import pprint
import time
import random
from collections import OrderedDict
import json

runtest = argparse.ArgumentParser(
    prog='bwruntests',
    formatter_class=argparse.RawDescriptionHelpFormatter,
    description="""Run PULP tests in parallel""",
    epilog="""
Test_file needs to be either a .yaml file (set the --yaml switch)
which looks like this:

mytests.yml
[...]
parallel_bare_tests: # name of the test set
  parMatrixMul8:     # name of the test
    path: ./parallel_bare_tests/parMatrixMul8 # path to the test's folder
    command: make clean all run # command to run in the test's folder
[...]

or

Test_file needs to be a list of commands to be executed. Each line corresponds
to a single command and a test

commands.f
[...]
make -C ./ml_tests/mlGrad clean all run
make -C ./ml_tests/mlDct clean all run
[...]

Example:
bwruntests.py --proc-verbose -v \\
    --report_junit -t 3600 --yaml \\
    -o simplified-runtime.xml runtime-tests.yaml

This Runs a set of tests defined in runtime-tests.yaml and dumps the
resulting junit.xml into simplified-runtime.xml. The --proc-verbose
scripts makes sure to print the stdout of each process to the shell. To
prevent a broken process from running forever, a maximum timeout of 3600
seconds was set. For debugging purposes we enabled -v (--verbose) which
shows the full set of commands being run.""")

runtest.version = '0.2'

runtest.add_argument('test_file', type=str,
                     help='file defining tests to be run')
runtest.add_argument('--version', action='version',
                     version='%(prog)s ' + runtest.version)
runtest.add_argument('-p', '--max_procs', type=int,
                     default=multiprocessing.cpu_count(),
                     help="""Number of parallel
                     processes used to run test.
                     Default is number of cpu cores.""")
runtest.add_argument('-t', '--timeout', type=float,
                     default=None,
                     help="""Timeout for all processes in seconds""")
runtest.add_argument('-v', '--verbose', action='store_true',
                     help="""Enable verbose output""")
runtest.add_argument('-s', '--proc_verbose', action='store_true',
                     help="""Write processes' stdout and stderr to shell stdout
                     after they terminate""")
runtest.add_argument('--report_junit', action='store_true',
                     help="""Generate a junit report""")
runtest.add_argument('--disable_junit_pp', action='store_true',
                     help="""Disable pretty print of junit report""")
runtest.add_argument('--disable_results_pp', action='store_true',
                     help="""Disable printing test results""")
runtest.add_argument('-y,', '--yaml', action='store_true',
                     help="""Read tests from yaml file instead of executing
                     from a list of commands""")
runtest.add_argument('-o,', '--output', type=str,
                     help="""Write junit.xml to file instead of stdout""")
runtest.add_argument('-P,', '--perf', type=str, default=None,
                     help="""Write performance results to JSON file""")
stdout_lock = Lock()

shared_total = 0
len_total = 0

class FinishedProcess(object):
    """A process that has finished running.
    """
    def __init__(self, name, cwd, runargs, returncode,
                 stdout=None, stderr=None, time=None):
        self.name = name
        self.cwd = cwd
        self.runargs = runargs
        self.returncode = returncode
        self.stdout = stdout
        self.stderr = stderr
        self.time = time
        exec_time = 0
        throughput = 0
        workload = 0
        if returncode == 0:
            matches = re.findall(r"# hwpe cycles =\s+(\d+)", stdout)
            if matches:
                exec_time = int(matches[0])
        self.exec_time = exec_time


    def __repr__(self):
        runargs = ['name={!r}'.format(self.name)]
        runargs += ['cwd={!r}'.format(self.cwd)]
        runargs += ['args={!r}'.format(self.runargs),
                 'returncode={!r}'.format(self.returncode)]
        if self.stdout is not None:
            runargs.append('stdout={!r}'.format(self.stdout))
        if self.stderr is not None:
            runargs.append('stderr={!r}'.format(self.stderr))
        if self.time is not None:
            runargs.append('time={!r}'.format(self.time))
        return "{}({})".format(type(self).__name__, ', '.join(runargs))

def fork(name, cwd, *popenargs, check=False, shell=True,
         **kwargs):
    """Run subprocess and return process args, error code, stdout and stderr
    """

    def proc_out(cwd, stdout, stderr):
        print('cwd={}'.format(cwd))
        print('stdout=')
        print(stdout.decode('utf-8'))
        print('stderr=')
        print(stderr.decode('utf-8'))

    kwargs['stdout'] = PIPE
    kwargs['stderr'] = PIPE

    with Popen(*popenargs, preexec_fn=os.setpgrp, cwd=cwd, shell=shell,
               **kwargs) as process:
        try:
            # Child and parent are racing for setting/using the pgid so we have
            # to set it in both processes. See glib manual.
            try:
                os.setpgid(process.pid, process.pid)
            except OSError as e:
                if e.errno != errno.EACCES:
                    raise
            # measure runtime
            start = time.time()
            stdout, stderr = process.communicate(input, timeout=proc_timeout)
        except TimeoutExpired:
            pgid = os.getpgid(process.pid)
            os.killpg(pgid, signal.SIGKILL)
            # process.kill() will only kill the immediate child but not its
            # forks. This won't work since our commands will create a few forks
            # (make -> vsim -> etc). We need to make a process group and kill
            # that
            stdout, stderr = process.communicate()
            timeoutmsg = 'TIMEOUT after {:f}s'.format(proc_timeout)

            if proc_verbose:
                stdout_lock.acquire()
                print(name)
                print(timeoutmsg)
                proc_out(cwd, stdout, stderr)
                stdout_lock.release()

            return FinishedProcess(name, cwd, process.args, 1,
                                   stdout.decode('utf-8'),
                                   timeoutmsg + '\n'
                                   + stderr.decode('utf-8'),
                                   time.time() - start)
        # Including KeyboardInterrupt, communicate handled that.
        except:  # noqa: E722
            pgid = os.getpgid(process.pid)
            os.killpg(pgid, signal.SIGKILL)
            # We don't call process.wait() as .__exit__ does that for us.
            raise
        retcode = process.poll()
        if check and retcode:
            raise CalledProcessError(retcode, process.args,
                                     output=stdout, stderr=stderr)
        if proc_verbose:
            stdout_lock.acquire()
            print(name)
            proc_out(cwd, stdout, stderr)
            stdout_lock.release()

    with lock:
        shared_total.value += 1
        print("[%s][%d/%d] %s" % ("\033[1;32m OK \033[0m" if retcode == 0 else "\033[1;31mFAIL\033[0m", shared_total.value, len_total.value, name))

    return FinishedProcess(name, cwd, process.args, retcode,
                           stdout.decode('utf-8'),
                           stderr.decode('utf-8'),
                           time.time() - start)

def poolInit(s, t, l, timeout, verbose):
    global shared_total
    global len_total
    global lock
    global proc_timeout
    global proc_verbose
    shared_total = s
    len_total = t
    lock = l
    proc_timeout = timeout
    proc_verbose = verbose

if __name__ == '__main__':
    args = runtest.parse_args()
    pp = pprint.PrettyPrinter(indent=4)

    # lazy importing so that we can work without junit_xml
    if args.report_junit:
        try:
            from junit_xml import TestSuite, TestCase
        except ImportError:
            print("""Error: The --report_junit option requires
the junit_xml library which is not installed.""",
                  file=sys.stderr)
            exit(1)

    # lazy import PrettyTable for displaying results
    if not(args.disable_results_pp):
        try:
            from prettytable import PrettyTable
        except ImportError:
            print("""Warning: Displaying results requires the PrettyTable
library which is not installed""")

    tests = []  # list of tuple (testname, working dir, command)

    # load tests (yaml or command list)
    if args.yaml:
        try:
            import yaml
        except ImportError:
            print("""Error: The --yaml option requires
the pyyaml library which is not installed.""",
                  file=sys.stderr)
            exit(1)
        with open(args.test_file) as f:
            testyaml = yaml.load(f, Loader=yaml.Loader)
            for testsetname, testv in testyaml.items():
                for testname, insn in testv.items():
                    cmd = insn['command']
                    cwd = insn['path']
                    tests.append((testsetname + ':' + testname, cwd, cmd))
            if args.verbose:
                pp.pprint(tests)
    else:  # (command list)
        with open(args.test_file) as f:
            testnames = list(map(str.rstrip, f))
            shellcmds = list(testnames)
            cwds = ['./' for e in testnames]
            tests = list(zip(testnames, cwds, shellcmds))
            if args.verbose:
                print('Tests which we are running:')
                pp.pprint(tests)
                pp.pprint(shellcmds)

    # Spawning process pool
    # Disable signals to prevent race. Child processes inherit SIGINT handler
    original_sigint_handler = signal.signal(signal.SIGINT, signal.SIG_IGN)
    lock = multiprocessing.Lock()
    shared_total = multiprocessing.Value('i', 0)
    len_total = multiprocessing.Value('i', len(tests))
    pool = multiprocessing.Pool(processes=args.max_procs, initializer=poolInit, initargs=(shared_total, len_total, lock, args.timeout, args.proc_verbose ))
    # Restore SIGINT handler
    signal.signal(signal.SIGINT, original_sigint_handler)
    # Shuffle tests
    random.shuffle(tests)
    try:
        procresults = pool.starmap(fork, tests)
    except KeyboardInterrupt:
        print("\nTerminating bwruntest.py")
        pool.terminate()
        pool.join()
        exit(1)

    # pp.pprint(procresults)
    pool.close()
    pool.join()

    # Generate junit.xml file. Junit.xml differentiates between failure and
    # errors but we treat everything as errors.
    if args.report_junit:
        testcases = []
        for p in procresults:
            # we can either expect p.name = testsetname:testname
            # or p.name = testname
            testcase = TestCase(p.name,
                                classname=((p.name).split(':'))[0],
                                stdout=p.stdout,
                                stderr=p.stderr,
                                elapsed_sec=p.time)
            if p.returncode != 0:
                testcase.add_failure_info(p.stderr)
            testcases.append(testcase)

        testsuite = TestSuite('bwruntests', testcases)
        if args.output:
            with open(args.output, 'w') as f:
                TestSuite.to_file(f, [testsuite],
                                  prettyprint=not(args.disable_junit_pp))
        else:
            print(TestSuite.to_xml_string([testsuite],
                                          prettyprint=(args.disable_junit_pp)))

    # # print JSON for performance regression
    # if args.perf is not None:
    #     # if file does not exist, create new dictionary:
    #     if not os.path.isfile(args.perf):
    #         d = OrderedDict([])
    #     # else, load the existing dictionary
    #     else:
    #         with open(args.perf) as f:
    #             d = json.load(f, object_pairs_hook=OrderedDict)
    #     # save the new execution times
    #     for p in procresults:
    #         if p.returncode == 0:
    #             d[p.name] = p.exec_time
    #     with open(args.perf, 'w', encoding='utf-8') as f:
    #         json.dump(d, f, ensure_ascii=False, indent=4)

    # print JSON for performance regression
    if args.perf is not None:
        # if file does not exist, create new dictionary:
        if not os.path.isfile(args.perf):
            d = list([])
        # else, load the existing dictionary
        else:
            with open(args.perf) as f:
                d = json.load(f)
        # save the new execution times
        for p in procresults:
            if p.returncode == 0:
                d.append({ 'name': p.name, 'value': p.exec_time, 'unit': 'cycles'})
        with open(args.perf, 'w', encoding='utf-8') as f:
            json.dump(d, f, ensure_ascii=False, indent=4)

    # print summary of test results
    if not(args.disable_results_pp):
        testcount = sum(1 for x in tests)
        testfailcount = sum(1 for p in procresults if p.returncode != 0)
        testpassedcount = testcount - testfailcount
        resulttable = PrettyTable(['test', 'cycles', 'time', 'passed/total'])
        resulttable.align['test'] = "l"
        for p in procresults:
            testpassed = 1 if p.returncode == 0 else 0
            testname = p.name
            resulttable.add_row([testname,
                                 p.exec_time,
                                 '{0:.2f}s'.format(p.time),
                                 '{0:d}/{1:d}'.format(testpassed, 1)])
        resulttable.add_row(['total', '', '', '{0:d}/{1:d}'.
                             format(testpassedcount, testcount)])
        print(resulttable)
        if testpassedcount != testcount:
            import sys; sys.exit(1)


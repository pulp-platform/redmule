# Copyright (C) 2022-2023 ETH Zurich and University of Bologna
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# SPDX-License-Identifier: Apache-2.0
#

common_targs += -t cv32e40p_exclude_tracer

ifeq ($(REDMULE_COMPLEX),1)
	common_targs += -t redmule_complex
else
	common_targs += -t redmule_hwpe
endif

common_defs  += -D COREV_ASSERT_OFF

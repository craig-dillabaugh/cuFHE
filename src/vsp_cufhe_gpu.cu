/**
 * Copyright 2018 Wei Dai <wdai3141@gmail.com>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */

#include <cuda.h>
#include <cuda_device_runtime_api.h>
#include <cuda_runtime.h>

#include <include/vsp_cufhe_gpu.cuh>
#include <include/details/vsp_allocator_gpu.cuh>

namespace vsp_cufhe {

uint32_t cnt = 0;


cuFHETRLWElvl1::cuFHETRLWElvl1()
{
    ctxtInitialize<TFHEpp::lvl1param::T, TFHEpp::TRLWE<TFHEpp::lvl1param>>(
        trlwehost, trlwedevices);
}

cuFHETRLWElvl1::~cuFHETRLWElvl1()
{
    ctxtDelete<TFHEpp::lvl1param::T, TFHEpp::TRLWE<TFHEpp::lvl1param>>(
        trlwehost, trlwedevices);
}

cuFHETRGSWNTTlvl1::cuFHETRGSWNTTlvl1()
{
    ctxtInitialize<FFP, TFHEpp::TRGSWNTT<TFHEpp::lvl1param>>(trgswhost,
                                                             trgswdevices);
}

cuFHETRGSWNTTlvl1::~cuFHETRGSWNTTlvl1()
{
    ctxtDelete<FFP, TFHEpp::TRGSWNTT<TFHEpp::lvl1param>>(trgswhost,
                                                         trgswdevices);
}

}  // namespace cufhe

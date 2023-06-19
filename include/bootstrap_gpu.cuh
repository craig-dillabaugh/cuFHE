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

#pragma once

#include <params.hpp>

#include "cufhe_gpu.cuh"
#include "details/allocator_gpu.cuh"

namespace cufhe {
void InitializeNTThandlers(const int gpuNum);
void BootstrappingKeyToNTT(
    const TFHEpp::BootstrappingKey<TFHEpp::lvl01param>& bk, const int gpuNum);
void DeleteBootstrappingKeyNTT(const int gpuNum);
void CMUXNTTkernel(TFHEpp::lvl1param::T* const res, const FFP* const cs,
                   TFHEpp::lvl1param::T* const c1,
                   TFHEpp::lvl1param::T* const c0, cudaStream_t st,
                   const int gpuNum);

void Bootstrap(TFHEpp::lvl0param::T* const out, const TFHEpp::lvl0param::T* const in,
               const TFHEpp::lvl1param::T mu, const cudaStream_t st, const int gpuNum);
void BootstrapTLWE2TRLWE(TFHEpp::lvl1param::T* const out, const TFHEpp::lvl0param::T* const in,
                         const TFHEpp::lvl1param::T mu, const cudaStream_t st,
                         const int gpuNum);
void SEIandBootstrap2TRLWE(TFHEpp::lvl1param::T* const out, const TFHEpp::lvl1param::T* const in,
                           const TFHEpp::lvl1param::T mu, const cudaStream_t st, const int gpuNum);

template<class brP, typename brP::targetP::T μ, class iksP>
void NandBootstrap(typename iksP::targetP::T* const out, const typename brP::domainP::T* const in0,
                   const typename brP::domainP::T* const in1, const cudaStream_t st, const int gpuNum);
template<class brP, typename brP::targetP::T μ, class iksP>
void OrBootstrap(typename iksP::targetP::T* const out, const typename brP::domainP::T* const in0,
                   const typename brP::domainP::T* const in1, const cudaStream_t st, const int gpuNum);
template<class brP, typename brP::targetP::T μ, class iksP>
void OrYNBootstrap(typename iksP::targetP::T* const out, const typename brP::domainP::T* const in0,
                   const typename brP::domainP::T* const in1, const cudaStream_t st, const int gpuNum);
template<class brP, typename brP::targetP::T μ, class iksP>
void OrNYBootstrap(typename iksP::targetP::T* const out, const typename brP::domainP::T* const in0,
                   const typename brP::domainP::T* const in1, const cudaStream_t st, const int gpuNum);
template<class brP, typename brP::targetP::T μ, class iksP>
void AndBootstrap(typename iksP::targetP::T* const out, const typename brP::domainP::T* const in0,
                   const typename brP::domainP::T* const in1, const cudaStream_t st, const int gpuNum);
template<class brP, typename brP::targetP::T μ, class iksP>
void AndYNBootstrap(typename iksP::targetP::T* const out, const typename brP::domainP::T* const in0,
                   const typename brP::domainP::T* const in1, const cudaStream_t st, const int gpuNum);
template<class brP, typename brP::targetP::T μ, class iksP>
void AndNYBootstrap(typename iksP::targetP::T* const out, const typename brP::domainP::T* const in0,
                   const typename brP::domainP::T* const in1, const cudaStream_t st, const int gpuNum);
template<class brP, typename brP::targetP::T μ, class iksP>
void NorBootstrap(typename iksP::targetP::T* const out, const typename brP::domainP::T* const in0,
                   const typename brP::domainP::T* const in1, const cudaStream_t st, const int gpuNum);
template<class brP, typename brP::targetP::T μ, class iksP>
void XorBootstrap(typename iksP::targetP::T* const out, const typename brP::domainP::T* const in0,
                   const typename brP::domainP::T* const in1, const cudaStream_t st, const int gpuNum);
template<class brP, typename brP::targetP::T μ, class iksP>
void XnorBootstrap(typename iksP::targetP::T* const out, const typename brP::domainP::T* const in0,
                   const typename brP::domainP::T* const in1, const cudaStream_t st, const int gpuNum);
void CopyBootstrap(TFHEpp::lvl0param::T* const out, const TFHEpp::lvl0param::T* const in,
                   const cudaStream_t st, const int gpuNum);
void NotBootstrap(TFHEpp::lvl0param::T* const out, const TFHEpp::lvl0param::T* const in,
                  const cudaStream_t st, const int gpuNum);
void MuxBootstrap(TFHEpp::lvl0param::T* const out, const TFHEpp::lvl0param::T* const inc,
                  const TFHEpp::lvl0param::T* const in1, const TFHEpp::lvl0param::T* const in0,
                  const cudaStream_t st, const int gpuNum);
void NMuxBootstrap(TFHEpp::lvl0param::T* const out, const TFHEpp::lvl0param::T* const inc,
                  const TFHEpp::lvl0param::T* const in1, const TFHEpp::lvl0param::T* const in0,
                  const cudaStream_t st, const int gpuNum);
}  // namespace cufhe

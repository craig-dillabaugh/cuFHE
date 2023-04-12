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

#include "ntt_ffp.cuh"
#include "ntt_1024_device.cuh"
#include "ntt_twiddle.cuh"
#include <include/details/math.h>
#include <include/details/error_gpu.cuh>
#include <params.hpp>

namespace cufhe {

template <uint32_t length = TFHEpp::lvl1param::n>
class CuNTTHandler: public CuTwiddle<length> {
public:

  __host__ __device__ inline
  CuNTTHandler() {};

  __host__ __device__ inline
  ~CuNTTHandler() {};

  inline
  void CreateConstant() {
    CuSafeCall(cudaMemcpyToSymbol(con_twd, this->twd_,
        sizeof(FFP) * length, 0,  cudaMemcpyDeviceToDevice));
    CuSafeCall(cudaMemcpyToSymbol(con_twd_inv, this->twd_inv_,
        sizeof(FFP) * length, 0, cudaMemcpyDeviceToDevice));
    CuSafeCall(cudaMemcpyToSymbol(con_twd_sqrt, this->twd_sqrt_,
        sizeof(FFP) * length, 0,  cudaMemcpyDeviceToDevice));
    CuSafeCall(cudaMemcpyToSymbol(con_twd_sqrt_inv, this->twd_sqrt_inv_,
        sizeof(FFP) * length, 0, cudaMemcpyDeviceToDevice));
  }

  template <typename T>
  __device__ inline
  void NTT(FFP* out,
           T* in,
           FFP* sh_temp,
           uint32_t leading_thread = 0) const {
    NTT1024<T>(out, in, sh_temp, this->twd_, this->twd_sqrt_, leading_thread);
  }

  template <typename T>
  __device__ inline
  void NTTInv(T* out,
              FFP* in,
              FFP* sh_temp,
              uint32_t leading_thread = 0) const {
    NTTInv1024<T>(out, in, sh_temp, this->twd_inv_, this->twd_sqrt_inv_,
                  leading_thread);
  }

  template <typename T>
  __device__ inline
  void NTTInvAdd(T* out,
                 FFP* in,
                 FFP* sh_temp,
                 uint32_t leading_thread = 0) const {
    NTTInv1024Add<T>(out, in, sh_temp, this->twd_inv_, this->twd_sqrt_inv_,
                     leading_thread);
  }

private:
  static const uint32_t kLength_ = length;
  static const uint32_t kLogLength_ = Log2Const(kLength_);
}; // class NTTHandler

template class CuNTTHandler<TFHEpp::lvl1param::n>;

} // namespace cufhe

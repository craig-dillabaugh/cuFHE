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

#include <bits/stdint-uintn.h>
#include <include/cufhe.h>
#include <stdio.h>
#include <unistd.h>

#include <include/cufhe_gpu.cuh>
#include <include/bootstrap_gpu.cuh>
#include <include/details/error_gpu.cuh>
#include <include/ntt_gpu/ntt.cuh>
#include <iostream>
#include <limits>
#include <vector>

namespace cufhe {
using namespace std;
using namespace TFHEpp;

vector<FFP*> bk_ntts;
vector<CuNTTHandler<>*> ntt_handlers;
vector<lvl0param::T*> ksk_devs;

__global__ void __TRGSW2NTT__(FFP* bk_ntt, TFHEpp::lvl1param::T* bk,
                                          CuNTTHandler<> ntt)
{
    __shared__ FFP sh_temp[lvl1param::n];
    const int index = blockIdx.z * (2 * lvl1param::l * 2 * lvl1param::n) +
                      blockIdx.y * 2 * lvl1param::n + blockIdx.x * lvl1param::n;
    ntt.NTT<lvl1param::T>(&bk_ntt[index], &bk[index], sh_temp, 0);
}

void TRGSW2NTT(cuFHETRGSWNTTlvl1& trgswntt, const TFHEpp::TRGSW<TFHEpp::lvl1param>& trgsw, Stream st){
    cudaSetDevice(st.device_id());
    TFHEpp::lvl1param::T* d_trgsw;
    cudaMalloc((void**)&d_trgsw, sizeof(trgsw));
    cudaMemcpyAsync(d_trgsw, trgsw.data(), sizeof(trgsw), cudaMemcpyHostToDevice,st.st());

    dim3 grid(2, 2 * lvl1param::l, 1);
    dim3 block(lvl1param::n >> NTT_THRED_UNITBIT);
    __TRGSW2NTT__<<<grid, block, 0, st.st()>>>(trgswntt.trgswdevices[st.device_id()], d_trgsw,
                                                *ntt_handlers[st.device_id()]);
    CuCheckError();
    cudaMemcpyAsync(trgswntt.trgswhost.data(), trgswntt.trgswdevices[st.device_id()],
                    sizeof(trgswntt.trgswhost), cudaMemcpyDeviceToHost, st.st());
    cudaFree(d_trgsw);
}

void InitializeNTThandlers(const int gpuNum){
    for (int i = 0; i < gpuNum; i++) {
        cudaSetDevice(i);

        ntt_handlers.push_back(new CuNTTHandler<>());
        ntt_handlers[i]->Create();
        ntt_handlers[i]->CreateConstant();
        cudaDeviceSynchronize();
        CuCheckError();
    }
}

void BootstrappingKeyToNTT(const BootstrappingKey<lvl01param>& bk,
                           const int gpuNum)
{
    bk_ntts.resize(gpuNum);
    for (int i = 0; i < gpuNum; i++) {
        cudaSetDevice(i);

        cudaMalloc((void**)&bk_ntts[i], sizeof(FFP) * lvl0param::n * 2 *
                                            lvl1param::l * 2 * lvl1param::n);

        TFHEpp::lvl1param::T* d_bk;
        cudaMalloc((void**)&d_bk, sizeof(bk));
        cudaMemcpy(d_bk, bk.data(), sizeof(bk), cudaMemcpyHostToDevice);

        cudaDeviceSynchronize();
        CuCheckError();

        dim3 grid(2, 2 * lvl1param::l, lvl0param::n);
        dim3 block(lvl1param::n >> NTT_THRED_UNITBIT);
        __TRGSW2NTT__<<<grid, block>>>(bk_ntts[i], d_bk,
                                                   *ntt_handlers[i]);
        cudaDeviceSynchronize();
        CuCheckError();

        cudaFree(d_bk);
    }
}

void DeleteBootstrappingKeyNTT(const int gpuNum)
{
    for (int i = 0; i < bk_ntts.size(); i++) {
        cudaSetDevice(i);
        cudaFree(bk_ntts[i]);

        ntt_handlers[i]->Destroy();
        delete ntt_handlers[i];
    }
    ntt_handlers.clear();
}

void KeySwitchingKeyToDevice(const KeySwitchingKey<lvl10param>& ksk,
                             const int gpuNum)
{
    ksk_devs.resize(gpuNum);
    for (int i = 0; i < gpuNum; i++) {
        cudaSetDevice(i);
        cudaMalloc((void**)&ksk_devs[i], sizeof(ksk));
        CuSafeCall(cudaMemcpy(ksk_devs[i], ksk.data(), sizeof(ksk),
                              cudaMemcpyHostToDevice));
    }
}

void DeleteKeySwitchingKey(const int gpuNum)
{
    for (int i = 0; i < ksk_devs.size(); i++) {
        cudaSetDevice(i);
        cudaFree(ksk_devs[i]);
    }
}

template <class P>
__device__ inline typename P::T modSwitchFromTorus(const uint32_t phase)
{
    constexpr uint32_t Mbit = P::nbit + 1;
    static_assert(32 >= Mbit, "Undefined modSwitchFromTorus!");
    return (phase + (1U << (31 - Mbit))) >> (32 - Mbit);
}

template <class P>
__device__ inline void KeySwitch(typename P::targetP::T* lwe,
                                 const typename P::domainP::T* const tlwe,
                                 const typename P::targetP::T* const ksk)
{
    constexpr typename P::domainP::T decomp_mask = (1U << P::basebit) - 1;
    constexpr typename P::domainP::T decomp_offset =
        1U << (std::numeric_limits<typename P::domainP::T>::digits - 1 -
               P::t * P::basebit);
    const uint32_t tid = ThisThreadRankInBlock();
    const uint32_t bdim = ThisBlockSize();
    for (int i = tid; i <= P::targetP::n; i += bdim) {
        typename P::targetP::T res = 0;
        if (i == P::targetP::n) res = tlwe[P::domainP::n];
        for (int j = 0; j < P::domainP::n; j++) {
            typename P::domainP::T tmp;
            if (j == 0)
                tmp = tlwe[0];
            else
                tmp = -tlwe[P::domainP::n - j];
            tmp += decomp_offset;
            for (int k = 0; k < P::t; k++) {
                typename P::domainP::T val =
                    (tmp >>
                     (std::numeric_limits<typename P::domainP::T>::digits -
                      (k + 1) * P::basebit)) &
                    decomp_mask;
                if (val != 0) {
                    constexpr int numbase = (1 << P::basebit) - 1;
                    res -= ksk[j * (lvl10param::t * numbase *
                                    (P::targetP::n + 1)) +
                               k * (numbase * (P::targetP::n + 1)) +
                               (val - 1) * (P::targetP::n + 1) + i];
                }
            }
        }
        lwe[i] = res;
    }
}

template <class P>
__device__ constexpr typename P::T offsetgen()
{
    typename P::T offset = 0;
    for (int i = 1; i <= P::l; i++)
        offset +=
            P::Bg / 2 *
            (1ULL << (numeric_limits<typename P::T>::digits - i * P::Bgbit));
    return offset;
}

__device__ inline void TRLWESubAndDecomposition(
    FFP* dectrlwe, const TFHEpp::lvl1param::T* const trlwe1, const TFHEpp::lvl1param::T* const trlwe0)
{
    const uint32_t tid = ThisThreadRankInBlock();
    const uint32_t bdim = ThisBlockSize();
    constexpr uint32_t decomp_mask = (1 << lvl1param::Bgbit) - 1;
    constexpr int32_t decomp_half = 1 << (lvl1param::Bgbit - 1);
    constexpr uint32_t decomp_offset = offsetgen<lvl1param>();
    constexpr typename lvl1param::T roundoffset = 1ULL<<(std::numeric_limits<typename lvl1param::T>::digits-lvl1param::l*lvl1param::Bgbit-1);
#pragma unroll
    for (int i = tid; i < lvl1param::n; i += bdim) {
        #pragma unroll
        for(int j = 0; j < 2; j ++){
            // decomp temp
            lvl1param::T temp = trlwe1[j*lvl1param::n+i]-trlwe0[j*lvl1param::n+i]+decomp_offset+roundoffset;
    #pragma unroll
            for (int digit = 0; digit < lvl1param::l; digit += 1)
                dectrlwe[j*lvl1param::l*lvl1param::n+digit * lvl1param::n + i] = FFP(lvl1param::T(
                    ((temp >> (std::numeric_limits<typename lvl1param::T>::digits -
                            (digit + 1) * lvl1param::Bgbit)) &
                    decomp_mask) -
                    decomp_half));
        }
    }
    __syncthreads();  // must
}

__global__ void __CMUXNTT__(TFHEpp::lvl1param::T* out, const FFP* const tgsw_ntt,
                                  const TFHEpp::lvl1param::T* const trlwe1,
                                  const TFHEpp::lvl1param::T* const trlwe0,
                                  const CuNTTHandler<> ntt)
{
    const uint32_t tid = ThisThreadRankInBlock();
    const uint32_t bdim = ThisBlockSize();

    extern __shared__ FFP sh[];
    // To hold the data after Decomposition and NTT
    FFP* sh_acc_ntt = &sh[0];
    // To hold sum
    FFP* sh_res_ntt = &sh[2*lvl1param::l*lvl1param::n];
    TFHEpp::lvl1param::T* outtemp =
        (TFHEpp::lvl1param::T*)&sh[0];

    TRLWESubAndDecomposition(sh_acc_ntt, trlwe1, trlwe0);

    // 2*l NTTs
    // Input/output/buffer use the same shared memory location.
    if (tid < 2*lvl1param::l * (lvl1param::n >> NTT_THRED_UNITBIT)) {
        FFP* tar = &sh_acc_ntt[tid >> (lvl1param::nbit - NTT_THRED_UNITBIT)
                                       << lvl1param::nbit];
        ntt.NTT<FFP>(tar, tar, tar,
                     tid >> (lvl1param::nbit - NTT_THRED_UNITBIT)
                                << (lvl1param::nbit - NTT_THRED_UNITBIT));
    }
    else {  // must meet 5 sync made by NTTInv
        __syncthreads();
        __syncthreads();
        __syncthreads();
        __syncthreads();
        __syncthreads();
    }
    __syncthreads();

// Multiply with bootstrapping key in global memory.
#pragma unroll
    for (int i = tid; i < lvl1param::n; i += bdim) {
        sh_res_ntt[i] = sh_acc_ntt[0 * lvl1param::n + i] *
                        tgsw_ntt[((2 * 0 + 0) << lvl1param::nbit) + i];
        sh_res_ntt[i + lvl1param::n] =
            sh_acc_ntt[0 * lvl1param::n + i] *
            tgsw_ntt[((2 * 0 + 1) << lvl1param::nbit) + i];
#pragma unroll
        for (int digit = 1; digit < 2*lvl1param::l; digit += 1) {
            sh_res_ntt[i] += sh_acc_ntt[digit * lvl1param::n + i] *
                             tgsw_ntt[((2 * digit + 0) << lvl1param::nbit) + i];
            sh_res_ntt[i + lvl1param::n] +=
                sh_acc_ntt[digit * lvl1param::n + i] *
                tgsw_ntt[((2 * digit + 1) << lvl1param::nbit) + i];
        }
    }
    __syncthreads();

    #pragma unroll
    for (int i = tid; i < 2*lvl1param::n; i += bdim) outtemp[i] = trlwe0[i];

    // 2 NTTInvs and add acc
    if (tid < 2 * (lvl1param::n >> NTT_THRED_UNITBIT)) {
        FFP* src = &sh_res_ntt[tid >> (lvl1param::nbit - NTT_THRED_UNITBIT)
                                          << lvl1param::nbit];
        ntt.NTTInvAdd<typename lvl1param::T>(
            &outtemp[tid >> (lvl1param::nbit - NTT_THRED_UNITBIT)
                             << lvl1param::nbit],
            src, src,
            tid >> (lvl1param::nbit - NTT_THRED_UNITBIT)
                       << (lvl1param::nbit - NTT_THRED_UNITBIT));
    }
    else {  // must meet 5 sync made by NTTInv
        __syncthreads();
        __syncthreads();
        __syncthreads();
        __syncthreads();
        __syncthreads();
    }
    __syncthreads();  // must
    for(int i = 0; i<2*lvl1param::n;i++) out[i] = outtemp[i];
    __syncthreads();
}

template <class P>
__device__ inline void RotatedTestVector(TFHEpp::lvl1param::T* tlwe,
                                         const int32_t bar,
                                         const typename P::T μ)
{
    // volatile is needed to make register usage of Mux to 128.
    // Reference
    // https://devtalk.nvidia.com/default/topic/466758/cuda-programming-and-performance/tricks-to-fight-register-pressure-or-how-i-got-down-from-29-to-15-registers-/
    volatile const uint32_t tid = ThisThreadRankInBlock();
    volatile const uint32_t bdim = ThisBlockSize();
#pragma unroll
    for (int i = tid; i < P::n; i += bdim) {
        tlwe[i] = 0;  // part a
        if (bar == 2 * P::n)
            tlwe[i + P::n] = μ;
        else {
            tlwe[i + P::n] = ((i < (bar & (P::n - 1))) ^ (bar >> P::nbit))
                                 ? -μ
                                 : μ;  // part b
        }
    }
    __syncthreads();
}

__device__ inline void PolynomialMulByXaiMinusOneAndDecompositionTRLWE(
    FFP* dectrlwe, const TFHEpp::lvl1param::T* const trlwe, const uint32_t a_bar)
{
    const uint32_t tid = ThisThreadRankInBlock();
    const uint32_t bdim = ThisBlockSize();
    constexpr uint32_t decomp_mask = (1 << lvl1param::Bgbit) - 1;
    constexpr int32_t decomp_half = 1 << (lvl1param::Bgbit - 1);
    constexpr uint32_t decomp_offset = offsetgen<lvl1param>();
    constexpr typename lvl1param::T roundoffset = 1ULL<<(std::numeric_limits<typename lvl1param::T>::digits-lvl1param::l*lvl1param::Bgbit-1);
#pragma unroll
    for (int i = tid; i < lvl1param::n; i += bdim) {
        #pragma unroll
        for (int j = 0; j < 2; j++){
            //PolynomialMulByXaiMinus
            lvl1param::T temp = trlwe[j*lvl1param::n + ((i - a_bar) & (lvl1param::n - 1))];
            temp = ((i < (a_bar & (lvl1param::n - 1)) ^ (a_bar >> lvl1param::nbit)))
                    ? -temp
                    : temp;
            temp -= trlwe[j*lvl1param::n + i];
            // decomp temp
            temp += decomp_offset + roundoffset;
    #pragma unroll
            for (int digit = 0; digit < lvl1param::l; digit += 1)
                dectrlwe[j*lvl1param::l*lvl1param::n + digit * lvl1param::n + i] = FFP(lvl1param::T(
                    ((temp >> (std::numeric_limits<typename lvl1param::T>::digits -
                            (digit + 1) * lvl1param::Bgbit)) &
                    decomp_mask) -
                    decomp_half));
        }
    }
    __syncthreads();  // must
}

__device__ inline void Accumulate(TFHEpp::lvl1param::T* trlwe,
                                  FFP* sh_acc_ntt, const uint32_t a_bar,
                                  const FFP* const tgsw_ntt,
                                  const CuNTTHandler<> ntt)
{
    const uint32_t tid = ThisThreadRankInBlock();
    const uint32_t bdim = ThisBlockSize();

    PolynomialMulByXaiMinusOneAndDecompositionTRLWE(sh_acc_ntt, trlwe, a_bar);

    // 2l NTTs
    // Input/output/buffer use the same shared memory location.
    if (tid < 2*lvl1param::l * (lvl1param::n >> NTT_THRED_UNITBIT)) {
        FFP* tar = &sh_acc_ntt[tid >> (lvl1param::nbit - NTT_THRED_UNITBIT)
                                       << lvl1param::nbit];
        ntt.NTT<FFP>(tar, tar, tar,
                     tid >> (lvl1param::nbit - NTT_THRED_UNITBIT)
                                << (lvl1param::nbit - NTT_THRED_UNITBIT));
    }
    else {  // must meet 5 sync made by NTTInv
        __syncthreads();
        __syncthreads();
        __syncthreads();
        __syncthreads();
        __syncthreads();
    }
    __syncthreads();

// Multiply with bootstrapping key in global memory.
#pragma unroll
    for (int i = tid; i < lvl1param::n; i += bdim) {
        sh_acc_ntt[2*lvl1param::l*lvl1param::n + i] =
            sh_acc_ntt[0 * lvl1param::n + i] *
            tgsw_ntt[((2 * 0 + 1) << lvl1param::nbit) + i];
        sh_acc_ntt[i] = sh_acc_ntt[0 * lvl1param::n + i] *
                        tgsw_ntt[((2 * 0 + 0) << lvl1param::nbit) + i];
#pragma unroll
        for (int digit = 1; digit < 2*lvl1param::l; digit += 1) {
            sh_acc_ntt[i] += sh_acc_ntt[digit * lvl1param::n + i] *
                             tgsw_ntt[((2 * digit + 0) << lvl1param::nbit) + i];
            sh_acc_ntt[2*lvl1param::l*lvl1param::n + i] +=
                sh_acc_ntt[digit * lvl1param::n + i] *
                tgsw_ntt[((2 * digit + 1) << lvl1param::nbit) + i];
        }
    }
    __syncthreads();

    // 2 NTTInvs and add acc
    if (tid < 2 * (lvl1param::n >> NTT_THRED_UNITBIT)) {
        FFP* src = &sh_acc_ntt[(tid >> (lvl1param::nbit - NTT_THRED_UNITBIT))*2*lvl1param::l*lvl1param::n];
        ntt.NTTInvAdd<typename lvl1param::T>(
            &trlwe[tid >> (lvl1param::nbit - NTT_THRED_UNITBIT)
                             << lvl1param::nbit],
            src, src,
            tid >> (lvl1param::nbit - NTT_THRED_UNITBIT)
                       << (lvl1param::nbit - NTT_THRED_UNITBIT));
    }
    else {  // must meet 5 sync made by NTTInv
        __syncthreads();
        __syncthreads();
        __syncthreads();
        __syncthreads();
        __syncthreads();
    }
    __syncthreads();  // must
}

__global__ void __Bootstrap__(TFHEpp::lvl0param::T* out,
                              TFHEpp::lvl0param::T* in,
                              const TFHEpp::lvl1param::T mu,
                              const FFP* const bk,
                              const TFHEpp::lvl0param::T* const ksk,
                              const CuNTTHandler<> ntt)
{
    //  Assert(bk.k() == 1);
    //  Assert(bk.l() == 2);
    //  Assert(bk.n() == lvl1param::n);
    extern __shared__ FFP sh[];
    FFP* sh_acc_ntt = &sh[0];
    // Use Last section to hold tlwe. This may to make these data in serial
    TFHEpp::lvl1param::T* tlwe =
        (TFHEpp::lvl1param::T*)&sh[(2 * lvl1param::l + 1) * lvl1param::n];

    // test vector
    // acc.a = 0; acc.b = vec(mu) * x ^ (in.b()/2048)
    {
        const uint32_t bar =
            2 * lvl1param::n - modSwitchFromTorus<lvl1param>(in[lvl0param::n]);
        RotatedTestVector<lvl1param>(tlwe, bar, mu);
    }

    // accumulate
    for (int i = 0; i < lvl0param::n; i++) {  // n iterations
        const uint32_t bar = modSwitchFromTorus<lvl1param>(in[i]);
        Accumulate(tlwe, sh_acc_ntt, bar,
                   bk + (i << lvl1param::nbit) * 2 * 2 * lvl1param::l, ntt);
    }

    KeySwitch<lvl10param>(out, tlwe, ksk);
    __threadfence();
}

__global__ void __SEandKS__(TFHEpp::lvl0param::T* out, TFHEpp::lvl1param::T* in,
                            FFP* bk, TFHEpp::lvl0param::T* ksk)
{
    KeySwitch<lvl10param>(out, in, ksk);
    __threadfence();
}

__global__ void __BootstrapTLWE2TRLWE__(TFHEpp::lvl1param::T* out,
                                        TFHEpp::lvl0param::T* in,
                                        TFHEpp::lvl1param::T mu, FFP* bk,
                                        CuNTTHandler<> ntt)
{
    //  Assert(bk.k() == 1);
    //  Assert(bk.l() == 2);
    //  Assert(bk.n() == lvl1param::n);
    extern __shared__ FFP sh[];
    FFP* sh_acc_ntt = &sh[0];
    // Use Last section to hold tlwe. This may to make these data in serial
    TFHEpp::lvl1param::T* tlwe =
        (TFHEpp::lvl1param::T*)&sh[(2 * lvl1param::l + 1) * lvl1param::n];

    // test vector
    // acc.a = 0; acc.b = vec(mu) * x ^ (in.b()/2048)
    register uint32_t bar =
        2 * lvl1param::n - modSwitchFromTorus<lvl1param>(in[lvl0param::n]);
    RotatedTestVector<lvl1param>(tlwe, bar, mu);

    // accumulate
    for (int i = 0; i < lvl0param::n; i++) {  // n iterations
        bar = modSwitchFromTorus<lvl1param>(in[i]);
        Accumulate(tlwe, sh_acc_ntt, bar,
                   bk + (i << lvl1param::nbit) * 2 * 2 * lvl1param::l, ntt);
    }
    __syncthreads();
    for (int i = 0; i < 2 * lvl1param::n; i++) {
        out[i] = tlwe[i];
    }
    __threadfence();
}

__global__ void __SEIandBootstrap2TRLWE__(TFHEpp::lvl1param::T* out,
                                        TFHEpp::lvl1param::T* in,
                                        TFHEpp::lvl1param::T mu, FFP* bk,
                                        TFHEpp::lvl0param::T* ksk,
                                        CuNTTHandler<> ntt)
{
    //  Assert(bk.k() == 1);
    //  Assert(bk.l() == 2);
    //  Assert(bk.n() == lvl1param::n);
    extern __shared__ FFP sh[];
    FFP* sh_acc_ntt = &sh[0];
    // Use Last section to hold tlwe. This may to make these data in serial
    TFHEpp::lvl1param::T* tlwe =
        (TFHEpp::lvl1param::T*)&sh[(2 * lvl1param::l + 2) * lvl1param::n];

    lvl0param::T* tlwelvl0 = (lvl0param::T*)&sh[(2 * lvl1param::l + 3) * lvl1param::n];

    KeySwitch<lvl10param>(tlwelvl0, in, ksk);
    __syncthreads();

    // test vector
    // acc.a = 0; acc.b = vec(mu) * x ^ (in.b()/2048)
    register uint32_t bar =
        2 * lvl1param::n - modSwitchFromTorus<lvl1param>(tlwelvl0[lvl0param::n]);
    RotatedTestVector<lvl1param>(tlwe, bar, mu);

    // accumulate
    for (int i = 0; i < lvl0param::n; i++) {  // n iterations
        bar = modSwitchFromTorus<lvl1param>(tlwelvl0[i]);
        Accumulate(tlwe, sh_acc_ntt, bar,
                   bk + (i << lvl1param::nbit) * 2 * 2 * lvl1param::l, ntt);
    }
    __syncthreads();
    for (int i = 0; i < 2 * lvl1param::n; i++) {
        out[i] = tlwe[i];
    }
    __threadfence();
}

template <int casign, int cbsign, typename lvl0param::T offset>
__device__ inline void __HomGate__(TFHEpp::lvl0param::T* out,
                                   TFHEpp::lvl0param::T* in0,
                                   TFHEpp::lvl0param::T* in1, FFP* bk,
                                   TFHEpp::lvl0param::T* ksk,
                                   CuNTTHandler<> ntt)
{
    extern __shared__ FFP sh[];
    FFP* sh_acc_ntt = &sh[0];
    // Use Last section to hold tlwe. This may to make these data in serial
    TFHEpp::lvl1param::T* tlwe =
        (TFHEpp::lvl1param::T*)&sh[(2 * lvl1param::l + 1) * lvl1param::n];

    // test vector: acc.a = 0; acc.b = vec(mu) * x ^ (in.b()/2048)
    {
        const uint32_t bar =
            2 * lvl1param::n -
            modSwitchFromTorus<lvl1param>(offset + casign * in0[lvl0param::n] +
                                          cbsign * in1[lvl0param::n]);
        RotatedTestVector<lvl1param>(tlwe, bar, lvl1param::μ);
    }

    // accumulate
    for (int i = 0; i < lvl0param::n; i++) {  // lvl0param::n iterations
        const uint32_t bar = modSwitchFromTorus<lvl1param>(0 + casign * in0[i] +
                                                           cbsign * in1[i]);
        Accumulate(tlwe, sh_acc_ntt, bar,
                   bk + (i << lvl1param::nbit) * 2 * 2 * lvl1param::l, ntt);
    }
    KeySwitch<lvl10param>(out, tlwe, ksk);
    __threadfence();
}

__global__ void __NandBootstrap__(TFHEpp::lvl0param::T* out,
                                  TFHEpp::lvl0param::T* in0,
                                  TFHEpp::lvl0param::T* in1, FFP* bk,
                                  TFHEpp::lvl0param::T* ksk, CuNTTHandler<> ntt)
{
    __HomGate__<-1, -1, lvl0param::μ>(out, in0, in1, bk, ksk, ntt);
}

__global__ void __NorBootstrap__(TFHEpp::lvl0param::T* out,
                                 TFHEpp::lvl0param::T* in0,
                                 TFHEpp::lvl0param::T* in1, FFP* bk,
                                 TFHEpp::lvl0param::T* ksk, CuNTTHandler<> ntt)
{
    __HomGate__<-1, -1, -lvl0param::μ>(out, in0, in1, bk, ksk, ntt);
}

__global__ void __XnorBootstrap__(TFHEpp::lvl0param::T* out,
                                  TFHEpp::lvl0param::T* in0,
                                  TFHEpp::lvl0param::T* in1, FFP* bk,
                                  TFHEpp::lvl0param::T* ksk, CuNTTHandler<> ntt)
{
    __HomGate__<-2, -2, -2 * lvl0param::μ>(out, in0, in1, bk, ksk, ntt);
}

__global__ void __AndBootstrap__(TFHEpp::lvl0param::T* out,
                                 TFHEpp::lvl0param::T* in0,
                                 TFHEpp::lvl0param::T* in1, FFP* bk,
                                 TFHEpp::lvl0param::T* ksk, CuNTTHandler<> ntt)
{
    __HomGate__<1, 1, -lvl0param::μ>(out, in0, in1, bk, ksk, ntt);
}

__global__ void __OrBootstrap__(TFHEpp::lvl0param::T* out,
                                TFHEpp::lvl0param::T* in0,
                                TFHEpp::lvl0param::T* in1, FFP* bk,
                                TFHEpp::lvl0param::T* ksk, CuNTTHandler<> ntt)
{
    __HomGate__<1, 1, lvl0param::μ>(out, in0, in1, bk, ksk, ntt);
}

__global__ void __XorBootstrap__(TFHEpp::lvl0param::T* out,
                                 TFHEpp::lvl0param::T* in0,
                                 TFHEpp::lvl0param::T* in1, FFP* bk,
                                 TFHEpp::lvl0param::T* ksk, CuNTTHandler<> ntt)
{
    __HomGate__<2, 2, 2*lvl0param::μ>(out, in0, in1, bk, ksk, ntt);
}

__global__ void __AndNYBootstrap__(TFHEpp::lvl0param::T* out,
                                   TFHEpp::lvl0param::T* in0,
                                   TFHEpp::lvl0param::T* in1, FFP* bk,
                                   TFHEpp::lvl0param::T* ksk,
                                   CuNTTHandler<> ntt)
{
    __HomGate__<-1, 1, -lvl0param::μ>(out, in0, in1, bk, ksk, ntt);
}

__global__ void __AndYNBootstrap__(TFHEpp::lvl0param::T* out,
                                   TFHEpp::lvl0param::T* in0,
                                   TFHEpp::lvl0param::T* in1, FFP* bk,
                                   TFHEpp::lvl0param::T* ksk,
                                   CuNTTHandler<> ntt)
{
    __HomGate__<1, -1, -lvl0param::μ>(out, in0, in1, bk, ksk, ntt);
}

__global__ void __OrNYBootstrap__(TFHEpp::lvl0param::T* out,
                                  TFHEpp::lvl0param::T* in0,
                                  TFHEpp::lvl0param::T* in1, FFP* bk,
                                  TFHEpp::lvl0param::T* ksk, CuNTTHandler<> ntt)
{
    __HomGate__<-1, 1, lvl0param::μ>(out, in0, in1, bk, ksk, ntt);
}

__global__ void __OrYNBootstrap__(TFHEpp::lvl0param::T* out,
                                  TFHEpp::lvl0param::T* in0,
                                  TFHEpp::lvl0param::T* in1, FFP* bk,
                                  TFHEpp::lvl0param::T* ksk, CuNTTHandler<> ntt)
{
    __HomGate__<1, -1, lvl0param::μ>(out, in0, in1, bk, ksk, ntt);
}

__global__ void __CopyBootstrap__(TFHEpp::lvl0param::T* out,
                                  TFHEpp::lvl0param::T* in)
{
    const uint32_t tid = ThisThreadRankInBlock();
    out[tid] = in[tid];
    __syncthreads();
    __threadfence();
}

__global__ void __NotBootstrap__(TFHEpp::lvl0param::T* out,
                                 TFHEpp::lvl0param::T* in)
{
    const uint32_t tid = ThisThreadRankInBlock();
    out[tid] = -in[tid];
    __syncthreads();
    __threadfence();
}

// Mux(inc,in1,in0) = inc?in1:in0 = inc&in1 + (!inc)&in0
__global__ void __MuxBootstrap__(TFHEpp::lvl0param::T* out,
                                 TFHEpp::lvl0param::T* inc,
                                 TFHEpp::lvl0param::T* in1,
                                 TFHEpp::lvl0param::T* in0, FFP* bk,
                                 TFHEpp::lvl0param::T* ksk, CuNTTHandler<> ntt)
{
    // To use over 48 KiB shared Memory, the dynamic allocation is required.
    extern __shared__ FFP sh[];
    FFP* sh_acc_ntt = &sh[0];
    // Use Last section to hold tlwe. This may to make these data in serial
    TFHEpp::lvl1param::T* tlwe1 =
        (TFHEpp::lvl1param::T*)&sh[(2*lvl1param::l + 1) * lvl1param::n];
    TFHEpp::lvl1param::T* tlwe0 =
        (TFHEpp::lvl1param::T*)&sh[(2*lvl1param::l + 2) * lvl1param::n];
    // test vector: acc.a = 0; acc.b = vec(mu) * x ^ (in.b()/2048)
    register uint32_t bar =
        2 * lvl1param::n -
        modSwitchFromTorus<lvl1param>(-lvl0param::μ + inc[lvl0param::n] +
                                      in1[lvl0param::n]);
    RotatedTestVector<lvl1param>(tlwe1, bar, lvl1param::μ);

    // accumulate
    for (int i = 0; i < lvl0param::n; i++) {  // lvl1param::n iterations
        bar = modSwitchFromTorus<lvl1param>(0 + inc[i] + in1[i]);
        Accumulate(tlwe1, sh_acc_ntt, bar,
                   bk + (i << lvl1param::nbit) * 2 * 2 * lvl1param::l, ntt);
    }

    bar = 2 * lvl1param::n -
          modSwitchFromTorus<lvl1param>(-lvl0param::μ - inc[lvl0param::n] +
                                        in0[lvl0param::n]);

    RotatedTestVector<lvl1param>(tlwe0, bar, lvl1param::μ);

    for (int i = 0; i < lvl0param::n; i++) {  // lvl1param::n iterations
        bar = modSwitchFromTorus<lvl1param>(0 - inc[i] + in0[i]);
        Accumulate(tlwe0, sh_acc_ntt, bar,
                   bk + (i << lvl1param::nbit) * 2 * 2 * lvl1param::l, ntt);
    }

    volatile const uint32_t tid = ThisThreadRankInBlock();
    volatile const uint32_t bdim = ThisBlockSize();
#pragma unroll
    for (int i = tid; i <= lvl1param::n; i += bdim) {
        tlwe1[i] += tlwe0[i];
        if (i == lvl1param::n) {
            tlwe1[lvl1param::n] += lvl1param::μ;
        }
    }

    __syncthreads();

    KeySwitch<lvl10param>(out, tlwe1, ksk);
    __threadfence();
}

// NMux(inc,in1,in0) = !(inc?in1:in0) = !(inc&in1 + (!inc)&in0)
__global__ void __NMuxBootstrap__(TFHEpp::lvl0param::T* out,
                                 TFHEpp::lvl0param::T* inc,
                                 TFHEpp::lvl0param::T* in1,
                                 TFHEpp::lvl0param::T* in0, FFP* bk,
                                 TFHEpp::lvl0param::T* ksk, CuNTTHandler<> ntt)
{
    // To use over 48 KiB shared Memory, the dynamic allocation is required.
    extern __shared__ FFP sh[];
    FFP* sh_acc_ntt = &sh[0];
    // Use Last section to hold tlwe. This may to make these data in serial
    TFHEpp::lvl1param::T* tlwe1 =
        (TFHEpp::lvl1param::T*)&sh[(2*lvl1param::l + 1) * lvl1param::n];
    TFHEpp::lvl1param::T* tlwe0 =
        (TFHEpp::lvl1param::T*)&sh[(2*lvl1param::l + 2) * lvl1param::n];
    
    // test vector: acc.a = 0; acc.b = vec(mu) * x ^ (in.b()/2048)
    register uint32_t bar =
        2 * lvl1param::n -
        modSwitchFromTorus<lvl1param>(-lvl0param::μ + inc[lvl0param::n] +
                                      in1[lvl0param::n]);
    RotatedTestVector<lvl1param>(tlwe1, bar, lvl1param::μ);

    // accumulate
    for (int i = 0; i < lvl0param::n; i++) {  // lvl1param::n iterations
        bar = modSwitchFromTorus<lvl1param>(0 + inc[i] + in1[i]);
        Accumulate(tlwe1, sh_acc_ntt, bar,
                   bk + (i << lvl1param::nbit) * 2 * 2 * lvl1param::l, ntt);
    }

    bar = 2 * lvl1param::n -
          modSwitchFromTorus<lvl1param>(-lvl0param::μ - inc[lvl0param::n] +
                                        in0[lvl0param::n]);

    RotatedTestVector<lvl1param>(tlwe0, bar, lvl1param::μ);

    for (int i = 0; i < lvl0param::n; i++) {  // lvl1param::n iterations
        bar = modSwitchFromTorus<lvl1param>(0 - inc[i] + in0[i]);
        Accumulate(tlwe0, sh_acc_ntt, bar,
                   bk + (i << lvl1param::nbit) * 2 * 2 * lvl1param::l, ntt);
    }

    volatile const uint32_t tid = ThisThreadRankInBlock();
    volatile const uint32_t bdim = ThisBlockSize();
#pragma unroll
    for (int i = tid; i <= lvl1param::n; i += bdim) {
        tlwe1[i] = -tlwe1[i]-tlwe0[i];
        if (i == lvl1param::n) {
            tlwe1[lvl1param::n] -= lvl1param::μ;
        }
    }

    __syncthreads();

    KeySwitch<lvl10param>(out, tlwe1, ksk);
    __threadfence();
}

constexpr uint NUM_THREAD4HOMGATE = 2 * lvl1param::l * lvl1param::n >>  NTT_THRED_UNITBIT;

void Bootstrap(TFHEpp::lvl0param::T* out, TFHEpp::lvl0param::T* in,
               lvl1param::T mu, cudaStream_t st, const int gpuNum)
{
    __Bootstrap__<<<1, NUM_THREAD4HOMGATE, 0,
                  st>>>
        (out, in, mu, bk_ntts[gpuNum], ksk_devs[gpuNum], *ntt_handlers[gpuNum]);
    CuCheckError();
}

void SEandKS(TFHEpp::lvl0param::T* out, TFHEpp::lvl1param::T* in,
             cudaStream_t st, const int gpuNum)
{
    __SEandKS__<<<1, lvl0param::n + 1, 0, st>>>(out, in, bk_ntts[gpuNum],
                                                ksk_devs[gpuNum]);
    CuCheckError();
}

void CMUXNTTkernel(TFHEpp::lvl1param::T* res, const FFP* const cs, TFHEpp::lvl1param::T* const c1, TFHEpp::lvl1param::T* const c0,
                         cudaStream_t st, const int gpuNum)
{
    cudaFuncSetAttribute(
        __CMUXNTT__, cudaFuncAttributeMaxDynamicSharedMemorySize,
        (2*lvl1param::l + 2) * lvl1param::n * sizeof(FFP));
    __CMUXNTT__<<<1, NUM_THREAD4HOMGATE,
                            (2*lvl1param::l + 2) * lvl1param::n * sizeof(FFP), st>>>
        (res, cs, c1, c0, *ntt_handlers[gpuNum]);
    CuCheckError();
}

constexpr uint MEM4HOMGATE = (2*lvl1param::l + 2) * lvl1param::n * sizeof(FFP);

void BootstrapTLWE2TRLWE(TFHEpp::lvl1param::T* out, TFHEpp::lvl0param::T* in,
                         lvl1param::T mu, cudaStream_t st, const int gpuNum)
{
    cudaFuncSetAttribute(
        __BootstrapTLWE2TRLWE__, cudaFuncAttributeMaxDynamicSharedMemorySize,
        MEM4HOMGATE);
    __BootstrapTLWE2TRLWE__<<<1, NUM_THREAD4HOMGATE,
                            MEM4HOMGATE, st>>>
        (out, in, mu, bk_ntts[gpuNum], *ntt_handlers[gpuNum]);
    CuCheckError();
}

void SEIandBootstrap2TRLWE(TFHEpp::lvl1param::T* out, TFHEpp::lvl1param::T* in,
                         lvl1param::T mu, cudaStream_t st, const int gpuNum)
{
    cudaFuncSetAttribute(
        __SEIandBootstrap2TRLWE__, cudaFuncAttributeMaxDynamicSharedMemorySize,
        ((2*lvl1param::l + 3) * lvl1param::n + (lvl0param::n + 1)/2+1) * sizeof(FFP));
    __SEIandBootstrap2TRLWE__<<<1, lvl1param::l * lvl1param::n>>
                                NTT_THRED_UNITBIT,
                            ((2*lvl1param::l + 3) * lvl1param::n + (lvl0param::n + 1)/2+1) * sizeof(FFP), st>>>
        (out, in, mu, bk_ntts[gpuNum], ksk_devs[gpuNum], *ntt_handlers[gpuNum]);
    CuCheckError();
}

void NandBootstrap(TFHEpp::lvl0param::T* out, TFHEpp::lvl0param::T* in0,
                   TFHEpp::lvl0param::T* in1, cudaStream_t st, const int gpuNum)
{
    cudaFuncSetAttribute(
        __NandBootstrap__, cudaFuncAttributeMaxDynamicSharedMemorySize,
        MEM4HOMGATE);
    __NandBootstrap__<<<1, NUM_THREAD4HOMGATE, MEM4HOMGATE,
                      st>>>
        (out, in0, in1, bk_ntts[gpuNum], ksk_devs[gpuNum],
         *ntt_handlers[gpuNum]);
    CuCheckError();
}

void OrBootstrap(TFHEpp::lvl0param::T* out, TFHEpp::lvl0param::T* in0,
                 TFHEpp::lvl0param::T* in1, cudaStream_t st, const int gpuNum)
{
    cudaFuncSetAttribute(
        __OrBootstrap__, cudaFuncAttributeMaxDynamicSharedMemorySize,
        MEM4HOMGATE);
    __OrBootstrap__<<<1, NUM_THREAD4HOMGATE, MEM4HOMGATE,
                    st>>>
        (out, in0, in1, bk_ntts[gpuNum], ksk_devs[gpuNum],
         *ntt_handlers[gpuNum]);
    CuCheckError();
}

void OrYNBootstrap(TFHEpp::lvl0param::T* out, TFHEpp::lvl0param::T* in0,
                   TFHEpp::lvl0param::T* in1, cudaStream_t st, const int gpuNum)
{
    cudaFuncSetAttribute(
        __OrYNBootstrap__, cudaFuncAttributeMaxDynamicSharedMemorySize,
        MEM4HOMGATE);
    __OrYNBootstrap__<<<1, NUM_THREAD4HOMGATE, MEM4HOMGATE,
                      st>>>
        (out, in0, in1, bk_ntts[gpuNum], ksk_devs[gpuNum],
         *ntt_handlers[gpuNum]);
    CuCheckError();
}

void OrNYBootstrap(TFHEpp::lvl0param::T* out, TFHEpp::lvl0param::T* in0,
                   TFHEpp::lvl0param::T* in1, cudaStream_t st, const int gpuNum)
{
    cudaFuncSetAttribute(
        __OrNYBootstrap__, cudaFuncAttributeMaxDynamicSharedMemorySize,
        MEM4HOMGATE);
    __OrNYBootstrap__<<<1, NUM_THREAD4HOMGATE, MEM4HOMGATE,
                      st>>>
        (out, in0, in1, bk_ntts[gpuNum], ksk_devs[gpuNum],
         *ntt_handlers[gpuNum]);
    CuCheckError();
}

void AndBootstrap(TFHEpp::lvl0param::T* out, TFHEpp::lvl0param::T* in0,
                  TFHEpp::lvl0param::T* in1, cudaStream_t st, const int gpuNum)
{
    cudaFuncSetAttribute(
        __AndBootstrap__, cudaFuncAttributeMaxDynamicSharedMemorySize,
        MEM4HOMGATE);
    __AndBootstrap__<<<1, NUM_THREAD4HOMGATE, MEM4HOMGATE,
                     st>>>
        (out, in0, in1, bk_ntts[gpuNum], ksk_devs[gpuNum],
         *ntt_handlers[gpuNum]);
    CuCheckError();
}

void AndYNBootstrap(TFHEpp::lvl0param::T* out, TFHEpp::lvl0param::T* in0,
                    TFHEpp::lvl0param::T* in1, cudaStream_t st, const int gpuNum)
{
    cudaFuncSetAttribute(
        __AndYNBootstrap__, cudaFuncAttributeMaxDynamicSharedMemorySize,
        MEM4HOMGATE);
    __AndYNBootstrap__<<<1, NUM_THREAD4HOMGATE, MEM4HOMGATE,
                       st>>>
        (out, in0, in1, bk_ntts[gpuNum], ksk_devs[gpuNum],
         *ntt_handlers[gpuNum]);
    CuCheckError();
}

void AndNYBootstrap(TFHEpp::lvl0param::T* out, TFHEpp::lvl0param::T* in0,
                    TFHEpp::lvl0param::T* in1, cudaStream_t st, const int gpuNum)
{
    cudaFuncSetAttribute(
        __AndNYBootstrap__, cudaFuncAttributeMaxDynamicSharedMemorySize,
        MEM4HOMGATE);
    __AndNYBootstrap__<<<1, NUM_THREAD4HOMGATE, MEM4HOMGATE,
                       st>>>
        (out, in0, in1, bk_ntts[gpuNum], ksk_devs[gpuNum],
         *ntt_handlers[gpuNum]);
    CuCheckError();
}

void NorBootstrap(TFHEpp::lvl0param::T* out, TFHEpp::lvl0param::T* in0,
                  TFHEpp::lvl0param::T* in1, cudaStream_t st, const int gpuNum)
{
    cudaFuncSetAttribute(
        __NorBootstrap__, cudaFuncAttributeMaxDynamicSharedMemorySize,
        MEM4HOMGATE);
    __NorBootstrap__<<<1, NUM_THREAD4HOMGATE, MEM4HOMGATE,
                     st>>>
        (out, in0, in1, bk_ntts[gpuNum], ksk_devs[gpuNum],
         *ntt_handlers[gpuNum]);
    CuCheckError();
}

void XorBootstrap(TFHEpp::lvl0param::T* out, TFHEpp::lvl0param::T* in0,
                  TFHEpp::lvl0param::T* in1, cudaStream_t st, const int gpuNum)
{
    cudaFuncSetAttribute(
        __XorBootstrap__, cudaFuncAttributeMaxDynamicSharedMemorySize,
        MEM4HOMGATE);
    __XorBootstrap__<<<1, NUM_THREAD4HOMGATE, MEM4HOMGATE,
                     st>>>
        (out, in0, in1, bk_ntts[gpuNum], ksk_devs[gpuNum],
         *ntt_handlers[gpuNum]);
    CuCheckError();
}

void XnorBootstrap(TFHEpp::lvl0param::T* out, TFHEpp::lvl0param::T* in0,
                   TFHEpp::lvl0param::T* in1, cudaStream_t st, const int gpuNum)
{
    cudaFuncSetAttribute(
        __XnorBootstrap__, cudaFuncAttributeMaxDynamicSharedMemorySize,
        MEM4HOMGATE);
    __XnorBootstrap__<<<1, NUM_THREAD4HOMGATE, MEM4HOMGATE,
                      st>>>
        (out, in0, in1, bk_ntts[gpuNum], ksk_devs[gpuNum],
         *ntt_handlers[gpuNum]);
    CuCheckError();
}

void CopyBootstrap(TFHEpp::lvl0param::T* out, TFHEpp::lvl0param::T* in,
                   cudaStream_t st, const int gpuNum)
{
    __CopyBootstrap__<<<1, lvl0param::n + 1, 0, st>>>(out, in);
    CuCheckError();
}

void NotBootstrap(TFHEpp::lvl0param::T* out, TFHEpp::lvl0param::T* in,
                  cudaStream_t st, const int gpuNum)
{
    __NotBootstrap__<<<1, lvl0param::n + 1, 0, st>>>(out, in);
    CuCheckError();
}

void MuxBootstrap(TFHEpp::lvl0param::T* out, TFHEpp::lvl0param::T* inc,
                  TFHEpp::lvl0param::T* in1, TFHEpp::lvl0param::T* in0,
                  cudaStream_t st, const int gpuNum)
{
    cudaFuncSetAttribute(
        __MuxBootstrap__, cudaFuncAttributeMaxDynamicSharedMemorySize,
        (2 * lvl1param::l + 3) * lvl1param::n * sizeof(FFP));
    __MuxBootstrap__<<<1, NUM_THREAD4HOMGATE,
                     (2 * lvl1param::l + 3) * lvl1param::n * sizeof(FFP),
                     st>>>
        (out, inc, in1, in0, bk_ntts[gpuNum], ksk_devs[gpuNum],
         *ntt_handlers[gpuNum]);
    CuCheckError();
}

void NMuxBootstrap(TFHEpp::lvl0param::T* out, TFHEpp::lvl0param::T* inc,
                  TFHEpp::lvl0param::T* in1, TFHEpp::lvl0param::T* in0,
                  cudaStream_t st, const int gpuNum)
{
    cudaFuncSetAttribute(
        __NMuxBootstrap__, cudaFuncAttributeMaxDynamicSharedMemorySize,
        (2 * lvl1param::l + 3) * lvl1param::n * sizeof(FFP));
    __NMuxBootstrap__<<<1, NUM_THREAD4HOMGATE,
                     (2 * lvl1param::l + 3) * lvl1param::n * sizeof(FFP),
                     st>>>
        (out, inc, in1, in0, bk_ntts[gpuNum], ksk_devs[gpuNum],
         *ntt_handlers[gpuNum]);
    CuCheckError();
}
}  // namespace cufhe

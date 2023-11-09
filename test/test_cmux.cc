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

// Include these two files for GPU computing.
#include <include/vsp_cufhe_gpu.cuh>
#include <include/ntt_gpu/vsp_ntt_ffp.cuh>
using namespace vsp_cufhe;

#include <iostream>
#include <random>
#include <vector>

int main()
{
    static_assert(sizeof(FFP) == sizeof(uint64_t));
    cudaSetDevice(0);
    cudaDeviceProp prop;
    cudaGetDeviceProperties(&prop, 0);
    const uint32_t kNumSMs = prop.multiProcessorCount * 10;
    const uint32_t kNumTests = kNumSMs * 32;  // * 8;

    std::cout << "------ Key Generation ------" << std::endl;
    TFHEpp::SecretKey *sk = new TFHEpp::SecretKey();

    std::vector<int32_t> ps(kNumTests);
    std::vector<std::array<uint8_t, TFHEpp::lvl1param::n>> p1(kNumTests);
    std::vector<std::array<uint8_t, TFHEpp::lvl1param::n>> p0(kNumTests);

    std::vector<TFHEpp::Polynomial<TFHEpp::lvl1param>> pmu1(kNumTests);
    std::vector<TFHEpp::Polynomial<TFHEpp::lvl1param>> pmu0(kNumTests);
    std::array<bool, TFHEpp::lvl1param::n> pres;

    std::random_device seed_gen;
    std::default_random_engine engine(seed_gen());
    std::uniform_int_distribution<uint32_t> binary(0, 1);

    std::cout << "------ Test Encryption/Decryption ------" << std::endl;
    for (int32_t &p : ps) p = binary(engine);
    for (std::array<uint8_t, TFHEpp::lvl1param::n> &i : p1)
        for (uint8_t &p : i) p = binary(engine);
    for (std::array<uint8_t, TFHEpp::lvl1param::n> &i : p0)
        for (uint8_t &p : i) p = binary(engine);

    for (int i = 0; i < kNumTests; i++)
        for (int j = 0; j < TFHEpp::lvl1param::n; j++)
            pmu1[i][j] =
                (p1[i][j] > 0) ? TFHEpp::lvl1param::μ : -TFHEpp::lvl1param::μ;
    for (int i = 0; i < kNumTests; i++)
        for (int j = 0; j < TFHEpp::lvl1param::n; j++)
            pmu0[i][j] =
                (p0[i][j] > 0) ? TFHEpp::lvl1param::μ : -TFHEpp::lvl1param::μ;

    std::vector<cuFHETRGSWNTTlvl1> csd(kNumTests);
    std::vector<cuFHETRLWElvl1> c1(kNumTests);
    std::vector<cuFHETRLWElvl1> c0(kNumTests);
    std::vector<cuFHETRLWElvl1> cres(kNumTests);
    Synchronize();

    std::vector<TFHEpp::TRGSW<TFHEpp::lvl1param>> cs(kNumTests);
    for (int i = 0; i < kNumTests; i++) {
        TFHEpp::Polynomial<TFHEpp::lvl1param> ply = {};
        ply[0] = ps[i];
        cs[i] = TFHEpp::trgswSymEncrypt<TFHEpp::lvl1param>(ply, TFHEpp::lvl1param::α,
                                                   sk->key.lvl1);
    }
    for (int i = 0; i < kNumTests; i++)
        c1[i].trlwehost =
            TFHEpp::trlweSymEncrypt<TFHEpp::lvl1param>(pmu1[i], TFHEpp::lvl1param::α, sk->key.lvl1);
    for (int i = 0; i < kNumTests; i++)
        c0[i].trlwehost =
            TFHEpp::trlweSymEncrypt<TFHEpp::lvl1param>(pmu0[i], TFHEpp::lvl1param::α, sk->key.lvl1);

    std::cout << "Number of tests:\t" << kNumTests << std::endl;

    std::cout << "------ Initilizating Data on GPU(s) ------" << std::endl;
    Initialize();  // essential for GPU computing

    Stream *st = new Stream[kNumSMs];
    for (int i = 0; i < kNumSMs; i++) st[i].Create();
    Synchronize();

    std::cout << "Number of streams:\t" << kNumSMs << std::endl;
    std::cout << "Number of tests:\t" << kNumTests << std::endl;
    std::cout << "Number of tests per stream:\t" << kNumTests / kNumSMs << std::endl;

    for (int i = 0; i < kNumTests; i++)
        csd[i].trgswhost = TFHEpp::TRGSW2NTT<TFHEpp::lvl1param>(cs[i]);

    float et;
    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);
    cudaEventRecord(start, 0);

    for (int i = 0; i < kNumTests; i++)
        CMUXNTT(cres[i], csd[i], c1[i], c0[i], st[i % kNumSMs]);
    Synchronize();

    cudaEventRecord(stop, 0);
    cudaEventSynchronize(stop);
    cudaEventElapsedTime(&et, start, stop);
    std::cout << et / kNumTests << " ms / gate" << std::endl;
    std::cout << et / kNumSMs << " ms / stream" << std::endl;
    cudaEventDestroy(start);
    cudaEventDestroy(stop);

    int count = 0;
    for (int test = 0; test < kNumTests; test++) {
        pres = TFHEpp::trlweSymDecrypt<TFHEpp::lvl1param>(cres[test].trlwehost,
                                                          sk->key.lvl1);
        for (int i = 0; i < TFHEpp::lvl1param::n; i++)
            count +=
                (pres[i] == ((ps[test] > 0) ? p1[test][i] : p0[test][i]) > 0)
                    ? 0
                    : 1;
    }
    std::cout << "count:" << count << std::endl;
    assert(count == 0);
    std::cout << "Passed" << std::endl;

    for (int i = 0; i < kNumSMs; i++) st[i].Destroy();
    delete[] st;

    std::cout << "------ Cleaning Data on GPU(s) ------" << std::endl;
    CleanUp();  // essential to clean and deallocate data
    return 0;
}

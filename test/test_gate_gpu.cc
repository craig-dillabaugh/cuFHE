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
#include <test/test_util.h>

#include <include/vsp_cufhe_gpu.cuh>

#include "plain.h"
using namespace vsp_cufhe;

#include <iostream>
#include <random>
#include <vector>
using namespace std;

int main()
{
    cudaSetDevice(0);
    cudaDeviceProp prop;
    cudaGetDeviceProperties(&prop, 0);
    const uint32_t kNumSMs = prop.multiProcessorCount;
    const uint32_t kNumTests = kNumSMs * 32;  // * 8;
    constexpr uint32_t kNumLevels = 10;  // Gate Types, Mux is counted as 2.

    // using Param = TFHEpp::lvl0param;
    using Param = TFHEpp::lvl1param;
    using brP = TFHEpp::lvl01param;
    using iksP = TFHEpp::lvl10param;

    TFHEpp::SecretKey* sk = new TFHEpp::SecretKey();
    TFHEpp::EvalKey ek;
    ek.emplacebk<brP>(*sk);
    ek.emplaceiksk<iksP>(*sk);

    cout << "n:" << sk->params.lvl0.n << endl;

    // MUX Need 3 input
    vector<uint8_t> pt(4 * kNumTests);
    vector<Ctxt<Param>> ct(4 * kNumTests);
    Synchronize();
    bool correct;

    cout << "Number of tests:\t" << kNumTests << endl;

    cout << "------ Initilizating Data on GPU(s) ------" << endl;
    Initialize(ek);  // essential for GPU computing

    Stream* st = new Stream[kNumSMs];
    for (int i = 0; i < kNumSMs; i++) st[i].Create();

    Test<Param>("NAND", Nand<Param>, NandCheck, pt, ct, st, kNumTests, kNumSMs, *sk);
    Test<Param>("OR", Or<Param>, OrCheck, pt, ct, st, kNumTests, kNumSMs, *sk);
    Test<Param>("ORYN", OrYN<Param>, OrYNCheck, pt, ct, st, kNumTests, kNumSMs, *sk);
    Test<Param>("ORNY", OrNY<Param>, OrNYCheck, pt, ct, st, kNumTests, kNumSMs, *sk);
    Test<Param>("AND", And<Param>, AndCheck, pt, ct, st, kNumTests, kNumSMs, *sk);
    Test<Param>("ANDYN", AndYN<Param>, AndYNCheck, pt, ct, st, kNumTests, kNumSMs, *sk);
    Test<Param>("ANDNY", AndNY<Param>, AndNYCheck, pt, ct, st, kNumTests, kNumSMs, *sk);
    Test<Param>("XOR", Xor<Param>, XorCheck, pt, ct, st, kNumTests, kNumSMs, *sk);
    Test<Param>("XNOR", Xnor<Param>, XnorCheck, pt, ct, st, kNumTests, kNumSMs, *sk);
    Test<Param>("MUX", Mux<Param>, MuxCheck, pt, ct, st, kNumTests, kNumSMs, *sk);
    Test<Param>("NMUX", NMux<Param>, NMuxCheck, pt, ct, st, kNumTests, kNumSMs, *sk);
    Test<Param>("NOT", Not<Param>, NotCheck, pt, ct, st, kNumTests, kNumSMs, *sk);
    Test<Param>("COPY", Copy<Param>, CopyCheck, pt, ct, st, kNumTests, kNumSMs, *sk);

    for (int i = 0; i < kNumSMs; i++) st[i].Destroy();
    delete[] st;

    cout << "------ Cleaning Data on GPU(s) ------" << endl;
    CleanUp();  // essential to clean and deallocate data
    return 0;
}

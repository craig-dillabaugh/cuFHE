#include <include/vsp_cufhe_gpu.cuh>

const size_t N = 20, M = 1000;

template <class Launcher, class Verifier>
void runAndVerify(const char* name, Launcher&& launcher, Verifier&& verifier)
{
    vsp_cufhe::Stream st[M];
    for (size_t i = 0; i < M; i++) st[i].Create();

    int workingIndex[M] = {};
    for (size_t i = 0; i < M; i++) launcher(0, i, st[i]);
    while (true) {
        bool cont = false;
        for (size_t i = 0; i < M; i++) {
            if (workingIndex[i] == N) continue;
            cont = true;

            if (vsp_cufhe::StreamQuery(st[i])) {
                int j = ++workingIndex[i];
                if (j == N) continue;
                launcher(j, i, st[i]);
            }
        }
        if (!cont) break;
    }
    cudaDeviceSynchronize();
    size_t errcount = 0;
    for (size_t i = 0; i < N; i++)
        for (size_t j = 0; j < M; j++)
            if (!verifier(i, j)) errcount++;
    if (errcount != 0)
        std::cerr << "TEST FAILED! " << name << " " << errcount << "/(" << N
                  << " * " << M << ")\n";
    assert(errcount == 0);

    for (size_t i = 0; i < M; i++) st[i].Destroy();
}

void testMux(TFHEpp::SecretKey& sk)
{
    vsp_cufhe::Ctxt<TFHEpp::lvl0param> ca, cb, cc, cres[N][M];
    bool pa, pb, pc;
    pa = true;
    pb = false;
    pc = true;
    bool expected = pa ? pb : pc;
    ca.tlwehost = TFHEpp::tlweSymEncrypt<TFHEpp::lvl0param>(
        pa ? TFHEpp::lvl0param::μ : -TFHEpp::lvl0param::μ, TFHEpp::lvl0param::α,
        sk.key.lvl0);
    cb.tlwehost = TFHEpp::tlweSymEncrypt<TFHEpp::lvl0param>(
        pb ? TFHEpp::lvl0param::μ : -TFHEpp::lvl0param::μ, TFHEpp::lvl0param::α,
        sk.key.lvl0);
    cc.tlwehost = TFHEpp::tlweSymEncrypt<TFHEpp::lvl0param>(
        pc ? TFHEpp::lvl0param::μ : -TFHEpp::lvl0param::μ, TFHEpp::lvl0param::α,
        sk.key.lvl0);

    runAndVerify(
        "mux",
        [&](size_t i, size_t j, vsp_cufhe::Stream st) {
            vsp_cufhe::Mux(cres[i][j], ca, cb, cc, st);
        },
        [&](size_t i, size_t j) {
            bool decres;
            decres = TFHEpp::tlweSymDecrypt<TFHEpp::lvl0param>(
                cres[i][j].tlwehost, sk.key.lvl0);
            return expected == decres;
        });
}

void testNand(TFHEpp::SecretKey& sk)
{
    vsp_cufhe::Ctxt<TFHEpp::lvl0param> ca, cb, cres[N][M];
    bool pa, pb;
    pa = true;
    pb = false;
    bool expected = !(pa && pb);
    ca.tlwehost = TFHEpp::tlweSymEncrypt<TFHEpp::lvl0param>(
        pa ? TFHEpp::lvl0param::μ : -TFHEpp::lvl0param::μ, TFHEpp::lvl0param::α,
        sk.key.lvl0);
    cb.tlwehost = TFHEpp::tlweSymEncrypt<TFHEpp::lvl0param>(
        pb ? TFHEpp::lvl0param::μ : -TFHEpp::lvl0param::μ, TFHEpp::lvl0param::α,
        sk.key.lvl0);

    runAndVerify(
        "nand",
        [&](size_t i, size_t j, vsp_cufhe::Stream st) {
            vsp_cufhe::Nand(cres[i][j], ca, cb, st);
        },
        [&](size_t i, size_t j) {
            bool decres;
            decres = TFHEpp::tlweSymDecrypt<TFHEpp::lvl0param>(
                cres[i][j].tlwehost, sk.key.lvl0);
            return expected == decres;
        });
}

int main()
{
    TFHEpp::SecretKey* sk = new TFHEpp::SecretKey();
    TFHEpp::EvalKey ek;
    ek.emplacebk<TFHEpp::lvl01param>(*sk);
    ek.emplaceiksk<TFHEpp::lvl10param>(*sk);
    vsp_cufhe::Initialize(ek);

    testNand(*sk);
    testMux(*sk);

    vsp_cufhe::CleanUp();
}

using LinearAlgebra, Libdl
println(stderr, "EXPECTED_OPENBLAS_CORE=", ENV["EXPECTED_OPENBLAS_CORE"])
found = false
for lib in BLAS.get_config().loaded_libs
    if occursin("openblas", lowercase(lib.libname))
        handle = Libdl.dlopen(lib.libname)
        ptr = Libdl.dlsym(handle, :openblas_get_corename64_)
        core = unsafe_string(ccall(ptr, Cstring, ()))
        println(stderr, "ACTUAL_OPENBLAS_CORE=", core)
        println(stderr, "OPENBLAS_LIBRARY=", lib.libname)
        @assert core == ENV["EXPECTED_OPENBLAS_CORE"]
        global found = true
    end
end
@assert found
flush(stderr)
include(joinpath(dirname(@__DIR__), "hosted-setup-validation", "run.jl"))

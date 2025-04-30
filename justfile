default: watch

check:
    $(vessel bin)/moc --check $(vessel sources) src/*.mo test/*.mo

test:
    $(vessel bin)/moc $(vessel sources) -wasi-system-api test/Test.test.mo
    wasmtime Test.test.wasm
    rm Test.test.wasm

test-mops:
    mops test --mode wasi

watch:
    watchexec just test

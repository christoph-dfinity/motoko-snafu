default:
    $(vessel bin)/moc $(vessel sources) src/*.mo

test:
    $(vessel bin)/moc $(vessel sources) -wasi-system-api test/Test.test.mo
    wasmtime Test.test.wasm

test-mops:
    mops test --mode wasi

watch:
    watchexec just test

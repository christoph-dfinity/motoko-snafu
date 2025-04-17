default:
    $(vessel bin)/moc $(vessel sources) src/*.mo

test:
    $(vessel bin)/moc $(vessel sources) -wasi-system-api test/Test.mo
    wasmtime Test.wasm

watch:
    watchexec just test

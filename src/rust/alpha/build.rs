use std::env;
use std::path::PathBuf;

fn main() {
    println!("cargo:rerun-if-changed=alpha_shape.c");
    println!("cargo:rerun-if-changed=alpha_shape.h");
    println!("cargo:rustc-link-lib=gmp");

    cc::Build::new()
        .cargo_metadata(true)
        .cpp(true)
        .flag("-lgmp")
        .flag("-frounding-math")
        .file("alpha_shape.c")
        .static_flag(true)
        .compile("libalpha.a");

    println!("cargo:rerun-if-changed=wrapper.hpp");

    let bindings = bindgen::Builder::default()
        // The input header we would like to generate
        // bindings for.
        .header("wrapper.hpp")
        // Tell cargo to invalidate the built crate whenever any of the
        // included header files changed.
        .parse_callbacks(Box::new(bindgen::CargoCallbacks))
        // Finish the builder and generate the bindings.
        .generate()
        // Unwrap the Result and panic on failure.
        .expect("Unable to generate bindings");

    let out_path = PathBuf::from(env::var("OUT_DIR").unwrap());
    bindings
        .write_to_file(out_path.join("bindings.rs"))
        .expect("Couldn't write bindings!");
}

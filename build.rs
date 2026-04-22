use flapigen::{JavaConfig, LanguageConfig};
use std::{env, path::{Path, PathBuf}};

fn main() {
    env_logger::init();

    let android = env::var_os("CARGO_FEATURE_ANDROID").is_some();
    let jvm = env::var_os("CARGO_FEATURE_JVM").is_some();
    if android && jvm {
        panic!("The `android` and `jvm` features are mutually exclusive");
    }

    let out_dir = env::var("OUT_DIR").unwrap();
    let in_src = Path::new("src").join("java_glue.rs.in");
    let out_src = Path::new(&out_dir).join("java_glue.rs");

    let (java_module, annotation_pkg): (PathBuf, &str) = if jvm {
        (PathBuf::from("client-jvm"), "com.etebase.client.annotation")
    } else {
        (PathBuf::from("client"), "androidx.annotation")
    };

    let java_out = java_module
        .join("src")
        .join("main")
        .join("java")
        .join("com")
        .join("etebase")
        .join("client");

    let swig_gen = flapigen::Generator::new(LanguageConfig::JavaConfig(
        JavaConfig::new(java_out, "com.etebase.client".into())
            .use_null_annotation_from_package(annotation_pkg.into()),
    ))
    .merge_type_map("typemaps", include_str!("src/jni_typemaps.rs"))
    .remove_not_generated_files_from_output_directory(true)
    .rustfmt_bindings(true);
    swig_gen.expand("etebase jni bindings", &in_src, &out_src);
    println!("cargo:rerun-if-changed={}", in_src.display());
}

use serde::{Deserialize, Serialize};
use serde_json::Result;
use std::fs;
use std::vec::Vec;

/* The JSON file full of structured HTTP error code infomation */
const HTTP_ERROR_JSON_FILE: &str = "errors.json";

/* The JSON will provide an array of HTTP error information */
#[derive(Serialize, Deserialize, Debug)]
struct HttpError {
    code: String,
    reason: String,
    description: String,
    link: String,
}

fn main() {
    /* Open and read the errors JSON from file */
    let errors = fs::read_to_string(HTTP_ERROR_JSON_FILE).unwrap();
    let errors: Vec<HttpError> = serde_json::from_str(&errors).unwrap();
    println!("{:#?}", errors);
}

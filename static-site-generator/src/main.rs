use fs_extra::dir;
use serde::{Deserialize, Serialize};
use std::convert::From;
use std::env;
use std::fs;
use std::path::{Path, PathBuf};
use std::vec::Vec;
use tinytemplate::TinyTemplate;

/* The JSON file full of structured HTTP error code infomation */
const HTTP_STATUS_CODE_JSON_FILE: &str = "statuses.json";
const STATUS_TEMPLATE_NAME: &str = "status_page";

/* The JSON will provide an array of HTTP status information */
#[derive(Serialize, Deserialize, Debug)]
struct HttpStatus {
    code: String,
    reason: String,
    description: String,
    link: String,
}

/* The tiny-template context struct */
#[derive(Serialize)]
struct Context {
    title: String,
    description: String,
    status_code: String,
    status_reason: String,
    status_description: String,
    status_spec_link: String,
}
impl From<HttpStatus> for Context {
    fn from(status: HttpStatus) -> Self {
        let HttpStatus {
            code: status_code,
            reason: status_reason,
            description: status_description,
            link: status_spec_link,
        } = status;
        Context {
            title: format!("{status_code} - {status_reason}"),
            description: format!(
                "Http Status Page - Returns the status, while presenting a page with the code, reason, and description. In this case: {status_code} - {status_reason} - {status_description}"
            ),
            status_code,
            status_reason,
            status_description,
            status_spec_link,
        }
    }
}

fn main() {
    /* Grab where to read the template from and where to place the generated results */
    let template_path = env::args().nth(1).unwrap_or("web".to_string());
    let output_path = env::args().nth(2).unwrap_or("results".to_string());

    println!("{:?}", template_path);
    println!("{:?}", output_path);

    /* Open and read the statuses from file */
    // let status_path = format!("./{template_path}/{HTTP_STATUS_CODE_JSON_FILE}");
    // let status_path = format!("Cargo.toml");
    let status_path = format!("{HTTP_STATUS_CODE_JSON_FILE}");
    println!("{}", status_path);
    let statuses = fs::read_to_string(&status_path).unwrap();

    /* Convert to the HttpStatus Code Format */
    let statuses: Vec<HttpStatus> = serde_json::from_str(&statuses).unwrap();

    /* Create the directory which will hold the completed website */
    let _ = fs::remove_dir_all(&output_path);
    fs::create_dir_all(&output_path).unwrap();
    /* Copy the static resources into the new directory */
    let options = dir::CopyOptions::new();
    dir::copy(format!("{template_path}/styles"), &output_path, &options).unwrap();
    dir::copy(format!("{template_path}/fonts"), &output_path, &options).unwrap();

    /* Initialize tiny-template */
    let mut tt = TinyTemplate::new();
    let template = fs::read_to_string(format!("{template_path}/template.html")).unwrap();
    tt.add_template(STATUS_TEMPLATE_NAME, &template).unwrap();

    /* Create each webpage */
    for status in statuses.into_iter() {
        /* Create template struct from the JSON info struct */
        let context: Context = status.into();
        let web_page = tt.render(STATUS_TEMPLATE_NAME, &context).unwrap();
        /* Name and place the web page into the final directory */
        let status_code = context.status_code;
        let filename = format!("{output_path}/{status_code}.html");
        fs::File::create(&filename).unwrap();
        fs::write(filename, web_page).unwrap();
    }
}

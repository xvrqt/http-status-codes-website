use fs_extra::dir;
use serde::{Deserialize, Serialize};
use std::convert::From;
use std::env;
use std::fs;
use std::vec::Vec;
use tinytemplate::TinyTemplate;

/* The JSON file full of structured HTTP error code infomation */
const INDEX_JSON_FILE: &str = "index.json";
const HTTP_STATUS_CODE_JSON_FILE: &str = "statuses.json";
const STATUS_TEMPLATE_NAME: &str = "status_page";
const INDEX_TEMPLATE_NAME: &str = "index_page";

/* index.json will be deserialized into a Vec of this struct */
#[derive(Serialize, Deserialize, Debug)]
struct HttpStatusGroup {
    title: String,
    description: String,
    link: String,
    // codes: [usize; 15],
    codes: Vec<usize>,
}
/* The tiny-template context struct */
#[derive(Serialize)]
struct IndexContext {
    groups: [HttpStatusGroup; 5],
}
impl From<[HttpStatusGroup; 5]> for IndexContext {
    fn from(groups: [HttpStatusGroup; 5]) -> Self {
        IndexContext { groups }
    }
}

/* statuses.json will be deserialized into a Vec of this struct */
#[derive(Serialize, Deserialize, Debug)]
struct HttpStatus {
    code: String,
    reason: String,
    description: String,
    link: String,
}

/* The tiny-template context struct */
#[derive(Serialize)]
struct StatusContext {
    title: String,
    description: String,
    status_code: String,
    status_reason: String,
    status_description: String,
    status_spec_link: String,
}
impl From<HttpStatus> for StatusContext {
    fn from(status: HttpStatus) -> Self {
        let HttpStatus {
            code: status_code,
            reason: status_reason,
            description: status_description,
            link: status_spec_link,
        } = status;
        StatusContext {
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
    let output_path = env::args().nth(2).unwrap_or("result".to_string());

    /* Open and read the statuses from file */
    let status_path = format!("{template_path}/{HTTP_STATUS_CODE_JSON_FILE}");
    let statuses = fs::read_to_string(&status_path).unwrap();

    /* Open and read the index information from file */
    let index_path = format!("{template_path}/{INDEX_JSON_FILE}");
    let index_contents = fs::read_to_string(&index_path).unwrap();

    /* Convert to the HttpStatus Code Format */
    let statuses: Vec<HttpStatus> = serde_json::from_str(&statuses).unwrap();
    /* Convert to the HttpStatusGroup Format */
    let index_contents: [HttpStatusGroup; 5] = serde_json::from_str(&index_contents).unwrap();

    /* Create the directory which will hold the completed website */
    let _ = fs::remove_dir_all(&output_path);
    fs::create_dir_all(&output_path).unwrap();
    /* Copy the static resources into the new directory */
    let options = dir::CopyOptions::new();
    dir::copy(format!("{template_path}/styles"), &output_path, &options).unwrap();
    dir::copy(format!("{template_path}/fonts"), &output_path, &options).unwrap();
    dir::copy(format!("{template_path}/icons"), &output_path, &options).unwrap();

    /* Initialize tiny-template */
    let mut tt = TinyTemplate::new();
    let status_template =
        fs::read_to_string(format!("{template_path}/status_template.html")).unwrap();
    tt.add_template(STATUS_TEMPLATE_NAME, &status_template)
        .unwrap();
    let index_template =
        fs::read_to_string(format!("{template_path}/index_template.html")).unwrap();
    tt.add_template(INDEX_TEMPLATE_NAME, &index_template)
        .unwrap();

    /* Create the index page */
    let context: IndexContext = index_contents.into();
    let index_page = tt.render(INDEX_TEMPLATE_NAME, &context).unwrap();
    let filename = format!("{output_path}/index.html");
    fs::File::create(&filename).unwrap();
    fs::write(filename, index_page).unwrap();

    /* Create each webpage */
    for status in statuses.into_iter() {
        /* Create template struct from the JSON info struct */
        let context: StatusContext = status.into();
        let web_page = tt.render(STATUS_TEMPLATE_NAME, &context).unwrap();
        /* Name and place the web page into the final directory */
        let status_code = context.status_code;
        let filename = format!("{output_path}/{status_code}.html");
        fs::File::create(&filename).unwrap();
        fs::write(filename, web_page).unwrap();
    }
}

use alpha::cgal_alpha_shape;
use clap::Parser;
use cmd_lib::run_cmd;
use common::{Article, ArticleRef, Votes};
use image::{ImageBuffer, Rgba};
use rayon::prelude::*;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::io::{BufRead, BufReader};
use std::path::{Path, PathBuf};
use svg::gen_svg;
use walkdir::WalkDir;

#[derive(Parser)]
struct Opts {
    #[clap(long)]
    root_dir: PathBuf,

    #[clap(long)]
    need_alpha_shapes: bool,
}

#[derive(Deserialize, Debug)]
struct ArticleFM {
    id: ArticleRef,
    vicpic: PathBuf,
    vicpic_small: PathBuf,
    permalink: String,
    score: f32,
    blurb: String,
    title: String,
    date: String,
    history: Vec<Votes>,
    color: bool,
    votes: u64,
}

#[derive(Serialize)]
struct ArticleJSON {
    title: String,
    title_plain: String,
    title_html: String,
    score: f32,
    date: String,
    votes: u64,
    url: String,
    vicsmall: PathBuf,
}

#[derive(Serialize, Debug)]
struct ZolaArticle {
    template: PathBuf,
    date: String,
    title: String,
    slug: String,
    extra: Extra,
}

#[derive(Serialize, Debug)]
struct Extra {
    score: f32,
    votes: u64,
    vicpic: PathBuf,
    vicpic_small: PathBuf,
    outlinks: Vec<ArticleRef>,
    inlinks: Vec<ArticleRef>,
    blurb: String,
    color: bool,
}

const SCORE_DATE: &str = "2009-12-09 15:45:37";

impl ArticleCommon for Article {
    fn votes(&self) -> Option<u64> {
        let history = self.history.iter().find(|h| h.date == SCORE_DATE)?;

        let count = history.votes.iter().sum();
        Some(count)
    }
    fn score(&self) -> Option<f32> {
        let history = self.history.iter().find(|h| h.date == SCORE_DATE)?;

        let count: u64 = history.votes.iter().sum();

        let value: u64 = history
            .votes
            .iter()
            .zip(1..)
            .map(|(count, value)| count * value)
            .sum();

        Some(value as f32 / count as f32)
    }
    fn yaml_title(&self) -> String {
        let regex = regex::Regex::new("[^a-zA-Z0-9 ]+").unwrap();
        let s = regex.replace_all(&self.title, "");
        let s = s.replace(' ', "-");
        s.to_owned().to_lowercase()
    }
    fn title_plain(&self) -> String {
        let title = self.title_html();
        let re = regex::Regex::new("<[^>]+>").unwrap();
        let title = re.replace_all(&title, "");
        title.to_string()
    }
    fn title_html(&self) -> String {
        use comrak::{format_html, parse_document, Arena, ComrakOptions};
        let arena = Arena::new();
        let root = parse_document(&arena, &self.title, &ComrakOptions::default());
        let mut html = vec![];
        format_html(root, &ComrakOptions::default(), &mut html).unwrap();
        String::from_utf8(html).unwrap()
    }
}

trait ArticleCommon {
    fn votes(&self) -> Option<u64>;
    fn score(&self) -> Option<f32>;
    fn yaml_title(&self) -> String;
    fn title_plain(&self) -> String;
    fn title_html(&self) -> String;
}

fn analyze_markdown(body: &str) -> (Vec<PathBuf>, Vec<ArticleRef>) {
    use comrak::arena_tree::NodeEdge;
    use comrak::nodes::NodeValue;
    use comrak::{parse_document, Arena, ComrakOptions};
    let arena = Arena::new();

    let root = parse_document(&arena, &body, &ComrakOptions::default());

    let article_conn = regex::Regex::new("@/victim/([0-9]+).md").unwrap();

    let mut imgs = vec![];
    let mut conns = vec![];

    root.traverse().for_each(|node| match node {
        NodeEdge::Start(node) | NodeEdge::End(node) => match &mut node.data.borrow_mut().value {
            &mut NodeValue::Image(ref link) => {
                imgs.push(
                    PathBuf::from(String::from_utf8(link.url.clone()).unwrap())
                        .strip_prefix("/")
                        .unwrap()
                        .to_path_buf(),
                );
            }
            &mut NodeValue::Link(ref link) => {
                if let Some(cap) =
                    article_conn.captures(&String::from_utf8(link.url.clone()).unwrap())
                {
                    conns.push(ArticleRef(cap[1].parse().unwrap()));
                }
            }
            _ => (),
        },
    });

    (imgs, conns)
}
fn main() -> std::io::Result<()> {
    let opts: Opts = Opts::parse();

    let victim_dir = opts.root_dir.join("src").join("victim");
    let json_dir = opts.root_dir.join("static").join("js").join("json");
    let victim_out_dir = opts.root_dir.join("content").join("victim");
    let articles = WalkDir::new(&victim_dir)
        .into_iter()
        .flat_map(|entry| {
            let entry = entry.unwrap();
            if entry.file_type().is_file()
                && matches!(
                    entry
                        .path()
                        .extension()
                        .map(|o| o.to_string_lossy().to_string())
                        .as_deref(),
                    Some("md")
                )
            {
                let article = std::fs::read_to_string(entry.path()).unwrap();

                let (article, body): (ArticleFM, _) =
                    serde_frontmatter::deserialize(&article).unwrap();
                let (mut imgs, mut conns) = analyze_markdown(&body);
                let (blurb_imgs, blurb_conns) = analyze_markdown(&article.blurb);
                imgs.extend(blurb_imgs);
                conns.extend(blurb_conns);

                conns.sort();
                conns.dedup();

                imgs.push(PathBuf::from("img").join(&article.vicpic_small));
                imgs.push(PathBuf::from("img").join(&article.vicpic));

                imgs.iter()
                    .map(|x| PathBuf::from("static").join(x))
                    .for_each(|i| {
                        assert!(
                            i.exists(),
                            "Missing img {} from {}",
                            i.display(),
                            entry.path().display()
                        );
                    });

                let article = Article {
                    body,
                    id: article.id,
                    vicpic: article.vicpic,
                    vicpic_small: article.vicpic_small,
                    permalink: article.permalink,
                    score: article.score,
                    blurb: article.blurb,
                    title: article.title,
                    date: article.date,
                    history: article.history,
                    color: article.color,
                    conns,
                };

                Some((article.id, article))
            } else {
                None
            }
        })
        .collect::<HashMap<_, _>>();

    let all_links = articles
        .iter()
        .flat_map(|(k, v)| v.conns.iter().map(move |c| (k, c)))
        .collect::<Vec<_>>();

    for (k, v) in &articles {
        let inlinks = all_links
            .iter()
            .filter(|(_src, dst)| *dst == k)
            .map(|(src, _dst)| *src)
            .cloned()
            .collect::<Vec<_>>();
        let outlinks = all_links
            .iter()
            .filter(|(src, _dst)| *src == k)
            .map(|(_src, dst)| *dst)
            .cloned()
            .collect::<Vec<_>>();

        let zola = ZolaArticle {
            template: PathBuf::from("article.html"),
            slug: format!("{}-{}", v.id.0, v.yaml_title()),
            date: v.date.clone(),
            title: v.title.clone(),
            extra: Extra {
                score: v.score().unwrap_or(0.0),
                votes: v.votes().unwrap_or(0),
                vicpic: v.vicpic.clone(),
                vicpic_small: v.vicpic_small.clone(),
                blurb: v.blurb.clone(),
                color: v.color,
                outlinks,
                inlinks,
            },
        };

        let doc = serde_frontmatter::serialize(&zola, &v.body).unwrap();
        std::fs::write(victim_out_dir.join(format!("{}.md", v.id.0)), &doc).unwrap()
    }

    let mut json_articles = HashMap::new();
    for (k, v) in &articles {
        let json = ArticleJSON {
            title: v.title.clone(),
            title_plain: v.title_plain(),
            title_html: v.title_html(),
            score: v.score().unwrap_or(0.0),
            vicsmall: v.vicpic_small.clone(),
            date: v.date.clone(),
            votes: v.votes().unwrap_or(0),
            url: v.permalink.clone(),
        };

        json_articles.insert(k, json);
    }
    std::fs::write(
        json_dir.join("articles.json"),
        serde_json::to_string(&json_articles).unwrap(),
    )
    .unwrap();

    let imgs: Vec<_> = articles
        .par_iter()
        .map(|(k, v)| {
            println!("Alpha {}", k.0);
            let mask = opts.root_dir.join("src").join(format!("{}.mask.png", k.0));
            let img = opts.root_dir.join("static").join("img").join(&v.vicpic);

            let mask_path = if mask.exists() {
                mask
            } else {
                let alpha = PathBuf::from("/tmp/").join(format!("{}.alpha", k.0));
                let mask = PathBuf::from(format!("/tmp/{}.mask.png", k.0));
                alpha_mask(*k, &img, &mask, &alpha);
                mask
            };

            let mask = image::open(mask_path).unwrap().to_luma8();

            let mut img = image::open(img).unwrap().to_rgba8();

            img.pixels_mut().zip(mask.pixels()).for_each(|(i, p)| {
                i[3] = p[0];
            });

            assert_eq!(img.dimensions(), mask.dimensions());

            if opts.need_alpha_shapes {
                let mut buf = vec![];
                cgal_alpha_shape(
                    img.enumerate_pixels()
                        .filter(|(_x, _y, p)| p[3] == 0xff)
                        .map(|(x, y, _p)| (x as i32, y as i32)),
                    |x1, y1, x2, y2| {
                        buf.push((x1, y1, x2, y2));
                    },
                );
            }
            (*k, img)
        })
        .collect();
    let comp_out = opts.root_dir.join(PathBuf::from("static/img/reunion.png"));
    composite(&comp_out, imgs);

    let plain = PathBuf::from("/tmp/dag.plain");
    let sprite = opts.root_dir.join(PathBuf::from("static/img/sprites.png"));
    let svg = opts.root_dir.join(PathBuf::from("static/img/dag.svg"));
    create_dag(&opts.root_dir, &plain, &articles).unwrap();
    gen_svg(&opts.root_dir, &plain, &svg, &sprite, &articles);
    Ok(())
}

fn create_dag(
    root: &Path,
    plain: &Path,
    articles: &HashMap<ArticleRef, Article>,
) -> Result<(), std::io::Error> {
    use std::io::Write;
    let mut out = tempfile::NamedTempFile::new().unwrap();

    writeln!(out, "digraph G {{")?;
    writeln!(out, "graph[size=\"7.75,10.25\"];")?;
    for (_, v) in articles {
        writeln!(
            out,
            "{} [nodesep=0.75,shape=square,image=\"{}\"];",
            v.id.0,
            root.join("static")
                .join("img")
                .join(&v.vicpic_small)
                .display()
        )?;
        for c in &v.conns {
            writeln!(out, "{} -> {};", v.id.0, c.0)?;
        }
    }

    writeln!(out, "}}")?;

    let out_path = out.path();

    run_cmd!(ignore ccomps -x -z ${out_path} | dot | gvpack -g | neato -s -y -n2 -Tplain -o ${plain})?;

    Ok(())
}

fn alpha_mask(id: ArticleRef, img: &Path, mask: &Path, alpha_data: &Path) {
    let alpha = tempfile::NamedTempFile::new().unwrap();
    let alpha = alpha.path();
    let threshold = match id.0 {
        10 => 0.2,
        11 => 0.05,
        15 => 0.2,
        25 => 0.1,
        26 => 0.1,
        27 => 0.1,
        28 => 0.05,
        29 => 0.05,
        34 => 0.2,
        38 => 0.5,
        42 => 0.7,
        46 => 0.5,
        206 => 0.4,
        599 => 0.4,
        625 => 0.2,
        696 => 10.0 / 255.0,
        v if v <= 48 => 10.0 / 255.0,
        _ => 0.5,
    } * 100.0;

    use std::borrow::Cow;
    let mut floods: Vec<Cow<str>> = vec![];
    let matte = |v: &mut Vec<Cow<str>>, r| {
        v.extend(["-draw".into(), format!("matte {} floodfill", r).into()])
    };
    let (w, _h) = image::io::Reader::open(img)
        .unwrap()
        .into_dimensions()
        .unwrap();
    matte(&mut floods, format!("{},{}", w - 1, 0));
    matte(&mut floods, format!("{},{}", 0, 0));

    if alpha_data.exists() {
        let alpha_data = std::fs::File::open(alpha_data).unwrap();
        let alpha_buf = BufReader::new(alpha_data);

        for l in alpha_buf.lines() {
            let l = l.unwrap();
            matte(&mut floods, l);
        }
    }
    let feather_size = 2;

    //let floods: Vec<_> = floods.iter().map(|f| f.as_ref()).collect();
    let floods = floods.iter().map(|f| f.as_ref());

    run_cmd!(
        convert ${img} -alpha set -channel RGBA -fuzz ${threshold}% -fill none $[floods] ${alpha};
        convert ${alpha} -alpha extract ${mask};
        feather -d ${feather_size} ${mask} ${mask}
    )
    .unwrap();
}

const SAME: &[&[usize]] = &[
    &[510, 501],
    &[517, 513],
    &[176, 164],
    &[68, 59],
    &[143, 135],
    &[271, 264],
    &[119, 109],
    &[101, 93],
    &[84, 76],
    &[241, 94],
    &[295, 287],
    &[95, 82],
    &[34, 13],
    &[160, 153],
    &[353, 346],
    &[259, 255],
    &[302, 147],
    &[523, 373],
    &[392, 386, 677],
    &[444, 437],
    &[432, 422],
    &[459, 452],
    &[466, 458],
    &[285, 63],
    &[478, 470, 651],
    &[551, 481, 685],
    &[494, 487],
    &[514, 509],
    &[526, 519],
    &[557, 553],
    &[601, 603],
    &[387, 381],
    &[403, 397],
    &[335, 328],
    &[596, 365, 356],
    &[484, 476],
    &[89, 70],
    &[38, 17],
    &[41, 23],
    &[52, 39],
    &[46, 31],
    &[389, 515],
    &[347, 340],
    &[137, 129],
    &[484, 476],
    &[211, 205],
    &[119, 109],
    //    &[362,465],
    //    &[349,525]
    &[595, 419, 436],
    &[490, 483],
    &[247, 237],
    &[42, 21],
    &[253, 244],
    //&[320,654],
    //&[467,579],
    //&[351,690],
    //&[350,673],
    &[298, 299, 300, 301],
    &[311, 304],
    //    &[393,411],
    &[539, 529],
    &[455, 448], //,374],
    &[500, 491, 611],
    &[200, 145],
    &[450, 422],
    &[505, 496],
    &[561, 556],
    &[572, 567],
    &[623, 615],
    &[62, 49],
    &[597, 450, 442],
    &[598, 486],
    &[188, 181],
    &[408, 402],
    &[206, 195],
    &[154, 146],
    &[148, 141],
    &[341, 331],
    &[235, 227],
    &[229, 221],
    &[323, 313],
    &[472, 461],
    //   &[440,672],
    &[371, 363],
    &[382, 379],
    &[370, 405],
    &[277, 270],
    &[113, 104],
    &[426, 418],
    &[359, 352],
    //    &[185,286],
    &[697, 695, 694],
    &[54, 284],
    &[176, 164],
    &[429, 438],
    &[309, 317, 680],
    &[414, 404],
    &[329, 319],
    &[275, 283],
    &[398, 388],
    &[74, 61],
    &[125, 123],
    &[182, 174],
    &[289, 278],
    &[265, 249],
    &[194, 186],
    &[217, 207],
    &[639, 570],
    //    &[100,282],
];

//411 link?
//425,362
//579 probably needs a link
//301 should link to 300

struct Img {
    #[allow(unused)]
    id: ArticleRef,
    image: ImageBuffer<Rgba<u8>, Vec<u8>>,
    place: Option<(u32, u32)>,
}

fn composite(output: &Path, imgs: Vec<(ArticleRef, ImageBuffer<Rgba<u8>, Vec<u8>>)>) {
    let dups: HashMap<ArticleRef, ArticleRef> = SAME
        .iter()
        .flat_map(|same| {
            same[1..]
                .iter()
                .cloned()
                .map(ArticleRef)
                .map(|dup| (dup, ArticleRef(same[0])))
        })
        .collect();

    let mut imgs: Vec<_> = imgs
        .into_iter()
        .filter(|(id, _)| dups.get(id).is_none())
        .map(|(id, image)| Img {
            id,
            image,
            place: None,
        })
        .collect();

    imgs.sort_by_key(|i| i.image.dimensions().1);
    imgs.reverse();

    let mut composite = image::RgbaImage::from_pixel(7000, 3200, Rgba([0xff, 0xff, 0xff, 0xff]));

    {
        let svg_data = std::fs::read("static/img/title.svg").unwrap();
        let opt = usvg::Options::default();
        let rtree = usvg::Tree::from_data(&svg_data, &opt).unwrap();

        let pixmap_size = rtree.svg_node().size.to_screen_size();
        let mut pixmap =
            tiny_skia::Pixmap::new(pixmap_size.width() * 10, pixmap_size.height() * 10).unwrap();
        resvg::render(&rtree, usvg::FitTo::Zoom(10.0), pixmap.as_mut()).unwrap();
        let title =
            ImageBuffer::<Rgba<u8>, _>::from_raw(pixmap.width(), pixmap.height(), pixmap.data())
                .unwrap();
        let x_pos = composite.width() / 2 - title.width() / 2;
        image::imageops::overlay(&mut composite, &title, x_pos, 0);
    }
    let mut place = (0, 500);
    let mut range = 0..composite.width() - 300;
    let mut start = true;
    for mut i in &mut imgs {
        if start {
            start = false;
        } else if !range.contains(&place.0) {
            let indent = 100;
            range.start += indent;
            range.end -= indent;
            place.1 += i.image.height() / 2;
            place.0 = range.start;
        } else {
            place.0 += i.image.width() / 2;
        };
        i.place = Some(place);
    }
    for i in &imgs {
        if let Some(placed) = i.place {
            image::imageops::overlay(&mut composite, &i.image, placed.0, placed.1);
        }
    }
    composite.save(output).unwrap();
}

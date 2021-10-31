use common::{Article, ArticleRef};
use dot;
use std::collections::HashMap;
use svg;

use svg::{
    node::element::{
        path::Data, ClipPath, Definitions, Group, Image, Path, Polygon, Rectangle,
    },
    node::Node,
    Document,
};

use std::path::PathBuf;

fn build_sprites(
    root: &std::path::Path,
    sprite: &std::path::Path,
    vics: &HashMap<ArticleRef, Article>,
) {
    let max = vics.iter().map(|(k, _v)| k.0 as u32).max().unwrap();
    use image::io::Reader as ImageReader;

    let width = 26;
    let tile_size = 100;
    let mut new = image::RgbaImage::new(width * tile_size, ((max / width) + 1) * tile_size);
    for (_, v) in vics {
        let img = ImageReader::open(root.join(PathBuf::from("static/img/").join(&v.vicpic_small)))
            .unwrap()
            .decode()
            .unwrap();
        let img = img.resize(100, 100, image::imageops::FilterType::Gaussian);
        image::imageops::overlay(
            &mut new,
            &img,
            (v.id.0 as u32 % width) * tile_size,
            v.id.0 as u32 / width * tile_size,
        );
    }

    new.save_with_format(sprite, image::ImageFormat::Png)
        .unwrap();
}

pub fn gen_svg(
    root: &std::path::Path,
    plain: &std::path::Path,
    svg: &std::path::Path,
    sprite: &std::path::Path,
    articles: &HashMap<ArticleRef, Article>,
) {
    build_sprites(root, sprite, articles);
    let s = plain;
    let s = std::fs::read_to_string(&s).unwrap();
    let (_, g) = dot::plain::parse(&s).unwrap();
    let g = &g[0];
    let mut doc = Document::new();

    doc.assign("viewBox", (0.0, 0.0, g.size.0, g.size.1));
    doc.assign("width", 100.0 * g.size.0);
    doc.assign("height", 100.0 * g.size.1);

    // doc.append(Image::new()
    //            .set("id", "sprites")
    //            .set("href", "sprites.png")
    // );
    let mut defs = Definitions::new();

    defs.append(Image::new().set("id", "sprites").set("href", "sprites.png"));

    for n in &g.nodes {
        let dot::plain::NodeId(id) = n.id;

        defs.append(
            ClipPath::new().set("id", format!("clip{}", id)).add(
                Rectangle::new()
                    .set("x", format!("{}px", (id % 26) * 100))
                    .set("y", format!("{}px", (id / 26) * 100))
                    .set("height", "100px")
                    .set("width", "100px"),
            ),
        )
    }
    defs.append(
        ClipPath::new().set("id", format!("clip_box")).add(
            Rectangle::new()
                .set("height", "100px")
                .set("width", "100px"),
        ),
    );

    doc.append(defs);

    for n in &g.nodes {
        let dot::plain::NodeId(id) = n.id;

        doc.append(
            Group::new()
                .add(
                    Document::new()
                        .set("x", n.top_left().0)
                        .set("y", n.top_left().1)
                        .set("height", "1")
                        .set("width", "1")
                        .set(
                            "viewBox",
                            format!("{} {} {} {}", (id % 26) * 100, (id / 26) * 100, 100, 100),
                        )
                        .add(Image::new().set("href", "/img/sprites.png")),
                )
                .add(
                    Polygon::new()
                        .set("fill", "none")
                        .set("stroke", "black")
                        .set("stroke-width", 0.01)
                        .set("points", n.pts().to_vec()),
                ), // .add(
                   //     Use::new()
                   //         .set("clip-path", format!("url(#clip{})", id))
                   //         .set("href", "#sprites")
                   //         .set("x", n.top_left().0)
                   //         .set("y", n.top_left().1)
                   //         .set("width", "100px")
                   //         .set("height", "100px")
                   // )
                   // .add(
                   //     Image::new()
                   //         .set("href", "sprites.png")
                   //         .set("clip-path", format!("url(#clip_box)"))
                   //         .set("transform", format!("translate(-{}, -{})",  (id % 26) * 100,  (id / 26) * 100 ))
                   //     )
        );
    }

    for e in &g.edges {
        doc.append(
            Group::new().add(
                Path::new()
                    .set("fill", "none")
                    .set("stroke", "black")
                    .set("stroke-width", 0.01)
                    .set(
                        "d",
                        Data::new().move_to(e.pts[0]).cubic_curve_to(
                            e.pts[1..]
                                .into_iter()
                                .cloned()
                                .flat_map(|(x, y)| [x, y])
                                .collect::<Vec<_>>(),
                        ),
                    ),
            ),
        );
    }
    svg::save(svg, &doc).unwrap();
}

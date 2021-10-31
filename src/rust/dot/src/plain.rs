use nom::{
    branch::alt,
    bytes::complete::{escaped_transform, tag},
    character::complete::{alphanumeric1, digit1, none_of},
    combinator::{map, map_res, opt, recognize, value},
    multi::{count, many0},
    sequence::tuple,
    IResult,
};

#[derive(Debug, PartialEq)]
pub struct NodeId(pub u32);

#[derive(Debug, PartialEq)]
pub struct Graph {
    pub scale: f32,
    pub size: (f32, f32),
    pub nodes: Vec<Node>,
    pub edges: Vec<Edge>,
}

#[derive(Debug, PartialEq)]
pub struct Edge {
    pub src: NodeId,
    pub dst: NodeId,
    pub pts: Vec<(f32, f32)>,
    pub style: Vec<String>,
}

#[derive(Debug, PartialEq)]
pub struct Node {
    pub id: NodeId,
    pub center: (f32, f32),
    pub size: (f32, f32),
    pub label: Option<String>,
    pub style: Vec<String>,
}

impl Node {
    pub fn top_left(&self) -> (f32, f32) {
        (
            self.center.0 - self.size.0 / 2.0,
            self.center.1 - self.size.1 / 2.0,
        )
    }
    pub fn pts(&self) -> [(f32, f32); 4] {
        let top_left = self.top_left();
        [
            top_left,
            (top_left.0 + self.size.0, top_left.1),
            (top_left.0 + self.size.0, top_left.1 + self.size.1),
            (top_left.0, top_left.1 + self.size.1),
        ]
    }
}

fn int(input: &str) -> IResult<&str, u32> {
    map_res(digit1, |digits: &str| digits.parse())(input)
}

fn float(input: &str) -> IResult<&str, f32> {
    map_res(
        recognize(tuple((digit1, opt(tuple((tag("."), digit1)))))),
        |float: &str| float.parse(),
    )(input)
}

fn word(input: &str) -> IResult<&str, &str> {
    recognize(alphanumeric1)(input)
}

fn node(input: &str) -> IResult<&str, Node> {
    let (input, id) = map(tuple((tag("node"), space, int)), |(_, _, id)| id)(input)?;

    let (input, rect) = count(map(tuple((space, float)), |t| t.1), 4)(input)?;

    let (input, label) = opt(map(
        tuple((
            space,
            tag("\""),
            alt((
                escaped_transform(
                    none_of("\\\""),
                    '\\',
                    alt((
                        /* this is probably not exhaustive */
                        value("\\", tag("\\")),
                        value("\"", tag("\"")),
                        value("\n", tag("n")),
                    )),
                ),
                map(tag(""), |_| "".to_string()),
            )),
            tag("\""),
        )),
        |t| t.2,
    ))(input)?;

    let (input, style) = many0(map(tuple((space, word)), |t| t.1.to_string()))(input)?;
    let (input, _) = tag("\n")(input)?;

    Ok((
        input,
        Node {
            id: NodeId(id),
            center: (rect[0], rect[1]),
            size: (rect[2], rect[3]),
            label,
            style,
        },
    ))
}

fn edge(input: &str) -> IResult<&str, Edge> {
    use std::convert::TryFrom;
    let (input, (src, dst, num_pts)) = map(
        tuple((tag("edge"), space, int, space, int, space, int)),
        |t| (t.2, t.4, t.6),
    )(input)?;

    let num_pts = usize::try_from(num_pts).unwrap();

    let (input, pts) = count(
        map(tuple((space, float, space, float)), |t| (t.1, t.3)),
        num_pts,
    )(input)?;

    let (input, style) = many0(map(tuple((space, word)), |t| t.1.to_string()))(input)?;
    let (input, _) = tag("\n")(input)?;

    Ok((
        input,
        Edge {
            src: NodeId(src),
            dst: NodeId(dst),
            pts,
            style,
        },
    ))
}

fn space(input: &str) -> IResult<&str, &str> {
    tag(" ")(input)
}

pub fn parse(input: &str) -> IResult<&str, Vec<Graph>> {
    map(
        tuple((
            many0(map(
                tuple((
                    map(
                        tuple((
                            tag("graph"),
                            space,
                            float,
                            space,
                            float,
                            space,
                            float,
                            tag("\n"),
                        )),
                        |(_, _, id, _, s1, _, s2, _)| (id, s1, s2),
                    ),
                    many0(node),
                    many0(edge),
                )),
                |((scale, s1, s2), nodes, edges)| Graph {
                    scale,
                    size: (s1, s2),
                    nodes,
                    edges,
                },
            )),
            tag("stop\n"),
        )),
        |(g, _)| g,
    )(input)
}

#[cfg(test)]
mod test {
    use super::*;
    #[test]
    fn edges() {
        assert_eq!(
            edge("edge 298 299 4 59.229 4.6889 59.121 4.8139 59.006 4.95 58.894 5.0792 solid black\n"),
            Ok(("",
               Edge {
                   src: NodeId(298),
                   dst: NodeId(299),
                   pts: vec![(59.229, 4.6889), (59.121, 4.8139), (59.006, 4.95), (58.894, 5.0792)],
                   style: vec!["solid".to_string(), "black".to_string()]
               }
            ))
        )
    }
    #[test]
    fn nodes() {
        assert_eq!(
            node("node 699 51.64 53.562 1.0694 1.0694 \"\" solid square black lightgrey\n"),
            Ok((
                "",
                Node {
                    id: NodeId(699),
                    size: (1.0694, 1.0694),
                    center: (51.64, 53.562),
                    label: "".to_string(),
                    style: vec![
                        "solid".to_string(),
                        "square".to_string(),
                        "black".to_string(),
                        "lightgrey".to_string()
                    ]
                }
            ))
        );
    }
    #[test]
    fn graph() {
        assert_eq!(
            parse(concat!(
                "graph 1 83.075 54.097\n",
                "node 699 51.64 53.562 1.0694 1.0694 \"test\\ntest2\\\"\" solid square black lightgrey\n",
                "edge 298 299 4 59.229 4.6889 59.121 4.8139 59.006 4.95 58.894 5.0792 solid black\n",
                "graph 2 83.075 54.097\n",
                "stop\n"
            )),
            Ok(("", vec![
                Graph {
                    id: 1.0,
                    size: (83.075, 54.097),
                    nodes : vec![
                        Node {
                            id: NodeId(699),
                            size: (1.0694, 1.0694),
                            center: (51.64, 53.562),
                            label: "test\ntest2\"".to_string(),
                            style: vec!["solid".to_string(), "square".to_string(), "black".to_string(),
                                        "lightgrey".to_string()]
                        }
                    ],
                    edges : vec![
                        Edge {
                            src: NodeId(298),
                            dst: NodeId(299),
                            pts: vec![(59.229, 4.6889), (59.121, 4.8139), (59.006, 4.95), (58.894, 5.0792)],
                            style: vec!["solid".to_string(), "black".to_string()]
                        }
                    ]
                },
                Graph {
                    scale: 2.0,
                    size: (83.075, 54.097),
                    nodes: vec![],
                    edges: vec![],
                }
            ]
        )));
    }
}

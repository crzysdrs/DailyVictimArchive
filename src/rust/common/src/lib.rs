use serde::{Deserialize, Serialize};
use std::path::PathBuf;

#[derive(Serialize, Deserialize, Debug, Eq, Hash, PartialEq, Copy, Clone, Ord, PartialOrd)]
pub struct ArticleRef(pub usize);

#[derive(Serialize, Deserialize, Debug)]
pub struct Votes {
    pub date: String,
    pub votes: Vec<u64>,
}

#[derive(Debug)]
pub struct Article {
    pub id: ArticleRef,
    pub vicpic: PathBuf,
    pub vicpic_small: PathBuf,
    pub permalink: String,
    pub score: f32,
    pub blurb: String,
    pub title: String,
    pub date: String,
    pub history: Vec<Votes>,
    pub color: bool,
    pub conns: Vec<ArticleRef>,
    pub body: String,
}

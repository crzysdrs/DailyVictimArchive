#![allow(non_upper_case_globals)]
#![allow(non_camel_case_types)]
#![allow(non_snake_case)]
use std::os::raw::{c_int, c_void};

include!(concat!(env!("OUT_DIR"), "/bindings.rs"));

unsafe extern "C" fn edge_callback<'a, EdgeFn>(
    data: *mut c_void,
    x1: c_int,
    y1: c_int,
    x2: c_int,
    y2: c_int,
) where
    EdgeFn: FnMut(i32, i32, i32, i32) + 'a,
{ unsafe {
    let edge_fn = std::mem::transmute::<_, &'a mut EdgeFn>(data);
    edge_fn(x1, y1, x2, y2);
}}

unsafe extern "C" fn point_callback<'a, PtFn>(
    data: *mut c_void,
    x1: *mut c_int,
    y1: *mut c_int,
) -> c_int
where
    PtFn: Iterator<Item = (i32, i32)> + 'a,
{ unsafe {
    let pt_fn = std::mem::transmute::<_, &'a mut PtFn>(data);
    if let Some(pt) = pt_fn.next() {
        *x1 = pt.0;
        *y1 = pt.1;
        return 1;
    } else {
        return 0;
    }
}}

pub fn cgal_alpha_shape<PtFn, EdgeFn>(mut pt: PtFn, mut edge: EdgeFn)
where
    PtFn: Iterator<Item = (i32, i32)>,
    EdgeFn: FnMut(i32, i32, i32, i32),
{
    unsafe {
        c_cgal_alpha_shape(
            Some(point_callback::<PtFn>),
            &mut pt as *mut _ as *mut c_void,
            Some(edge_callback::<EdgeFn>),
            &mut edge as *mut _ as *mut c_void,
        );
    }
}

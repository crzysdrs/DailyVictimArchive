#include <CGAL/Exact_predicates_inexact_constructions_kernel.h>
#include <CGAL/algorithm.h>
#include <CGAL/Delaunay_triangulation_2.h>
#include <CGAL/Alpha_shape_2.h>
#include <iostream>
#include <fstream>
#include <vector>
#include <list>
//#include <Magick++.h>
#include "alpha_shape.h"

typedef CGAL::Exact_predicates_inexact_constructions_kernel K;
typedef K::FT FT;
typedef K::Point_2  Point;
typedef K::Segment_2  Segment;
typedef CGAL::Alpha_shape_vertex_base_2<K> Vb;
typedef CGAL::Alpha_shape_face_base_2<K>  Fb;
typedef CGAL::Triangulation_data_structure_2<Vb,Fb> Tds;
typedef CGAL::Delaunay_triangulation_2<K,Tds> Triangulation_2;
typedef CGAL::Alpha_shape_2<Triangulation_2>  Alpha_shape_2;
typedef Alpha_shape_2::Alpha_shape_edges_iterator Alpha_shape_edges_iterator;

extern "C" void c_cgal_alpha_shape(PointFn next_point_fn, void * pt_data, OutputEdge edge_fn, void * edge_data) 
{
    std::list<Point> points;
    int x = 0;
    int y = 0;
    while (next_point_fn(pt_data, &x, &y)) {
        points.push_back(Point(x, y));
    }
    Alpha_shape_2 A(
        points.begin(), points.end(),
        FT(5),
        Alpha_shape_2::GENERAL);

    for(Alpha_shape_edges_iterator it =  A.alpha_shape_edges_begin(); 
        it != A.alpha_shape_edges_end();
        ++it){ 
        auto segment = A.segment(*it);
        edge_fn(
            edge_data,
            segment.source().x(), segment.source().y(),
            segment.target().x(), segment.target().y()
                ); 
    }  
}

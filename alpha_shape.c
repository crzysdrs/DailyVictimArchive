#include <CGAL/Exact_predicates_inexact_constructions_kernel.h>
#include <CGAL/algorithm.h>
#include <CGAL/Delaunay_triangulation_2.h>
#include <CGAL/Alpha_shape_2.h>
#include <iostream>
#include <fstream>
#include <vector>
#include <list>
#include <Magick++.h>

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

template <class OutputIterator>
void
alpha_edges( const Alpha_shape_2&  A,
         OutputIterator out)
{
  for(Alpha_shape_edges_iterator it =  A.alpha_shape_edges_begin();
      it != A.alpha_shape_edges_end();
      ++it){
    *out++ = A.segment(*it);
  }
}
template <class OutputIterator>
bool
file_input(char * file, OutputIterator out)
{
  std::ifstream is(file, std::ios::in);
  if(is.fail()){
    std::cerr << "unable to open file " << file << " for input" << std::endl;
    return false;
  }
  int n;
  is >> n;
  if (n > 0) {
    std::cout << "Reading " << n << " points from " << file << std::endl;
    CGAL::cpp11::copy_n(std::istream_iterator<Point>(is), n, out);
    return true;
  } else {
    return false;
  }
}
template <class OutputIterator>
bool
img_input(char * img, OutputIterator out) 
{
    Magick::Image image;
    try {
        image.read(img);
        Magick::Pixels view(image);
        int count = 0;
        for (int y = 0; y < image.rows(); y++) {
            for (int x = 0; x < image.columns(); x++) {           
                Magick::Color c = image.pixelColor(x, y);
                if (c.redQuantum() > 0 || c.blueQuantum() > 0 || c.greenQuantum() > 0) {
                    count++;
                    *out = Point(x, y);
                    out++;
                }
            }
        }
        return count > 1;
    } catch (Magick::Exception & ex) {
        std::cout << "Caught exception: " << ex.what() << std::endl; 
        return false;
    }
}

// Reads a list of points and returns a list of segments
// corresponding to the Alpha shape.
int main(int argc, char * argv[]) 
{
  Magick::InitializeMagick(*argv);
  std::list<Point> points;
  if (argc < 3) {
    return -1;
  }
  char * in_file = argv[2];
  char * out_file = argv[1];
  if(! img_input(in_file, std::back_inserter(points))){
    return 0;
  }
  Alpha_shape_2 A(points.begin(), points.end(),
          FT(5),
          Alpha_shape_2::GENERAL);
  std::vector<Segment> segments;
  alpha_edges( A, std::back_inserter(segments));
  std::cout << "Alpha Shape computed" << std::endl;
  std::cout << segments.size() << " alpha shape edges" << std::endl;
  std::cout << "Optimal alpha: " << *A.find_optimal_alpha(1)<<std::endl;

  FILE * f = fopen(out_file, "w");
  for (int x = 0; x < segments.size(); x++) {
    fprintf(f, "%f,%f %f,%f\n", segments[x].source().x(), segments[x].source().y(),
	    segments[x].target().x(), segments[x].target().y());
  }
  fclose(f);
  return 0;
}

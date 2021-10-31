typedef int (*PointFn)(void * data, int * x, int * y);
typedef void (*OutputEdge)(void *data, int x1, int y1, int x2, int y2);

extern "C" void c_cgal_alpha_shape(PointFn next_point_fn, void * pt_data, OutputEdge edge_fn, void * edge_data) ;


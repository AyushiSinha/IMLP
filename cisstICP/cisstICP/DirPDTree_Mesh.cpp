// ****************************************************************************
//
//    Copyright (c) 2014, Seth Billings, Russell Taylor, Johns Hopkins University
//    All rights reserved.
//
//    Redistribution and use in source and binary forms, with or without
//    modification, are permitted provided that the following conditions are
//    met:
//
//    1. Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer.
//
//    2. Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in the
//    documentation and/or other materials provided with the distribution.
//
//    3. Neither the name of the copyright holder nor the names of its
//    contributors may be used to endorse or promote products derived from
//    this software without specific prior written permission.
//
//    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
//    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
//    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
//    A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
//    HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
//    SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
//    LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
//    DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
//    THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//    (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
//    OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//  
// ****************************************************************************
#include "DirPDTree_Mesh.h"


DirPDTree_Mesh::DirPDTree_Mesh( cisstMesh mesh, int countThresh, double diagThresh )
{ 
  this->mesh = mesh;

  NData = mesh.NumTriangles();
  DataIndices = new int[NData];
  for (int i=0;i<NData;i++) 
  { 
    DataIndices[i]=i;
  }
  Top = new DirPDTreeNode(DataIndices,NData,this,NULL);
  NNodes = 0; NNodes++;
  treeDepth = Top->ConstructSubtree(countThresh,diagThresh);

#ifdef DebugDirPDTree
  fprintf(debugFile, "Directional Mesh Cov Tree built: NNodes=%d  NData=%d  TreeDepth=%d\n", NumNodes(), NumData(), TreeDepth());
#endif
}

DirPDTree_Mesh::~DirPDTree_Mesh()
{
  if (Top) delete Top;
  if (DataIndices) delete DataIndices;
}

vct3 DirPDTree_Mesh::DatumSortPoint(int datum)
{ 
  //// use vertex 0 as the sort point
  //return mesh.FaceCoord(datum, 0);

  // use triangle center as the sort point
  return (mesh.FaceCoord(datum, 0) +
    mesh.FaceCoord(datum, 1) +
    mesh.FaceCoord(datum, 2)) / 3.0;
}

vct3 DirPDTree_Mesh::DatumNorm(int datum)
{
  return mesh.faceNormals(datum);
}

void DirPDTree_Mesh::EnlargeBounds(const vctFrm3& F, int datum, BoundingBox& BB)
{ 
  vct3 v1, v2, v3;
  mesh.FaceCoords(datum, v1, v2, v3);
  BB.Include(F*v1);
  BB.Include(F*v2);
  BB.Include(F*v3);
}

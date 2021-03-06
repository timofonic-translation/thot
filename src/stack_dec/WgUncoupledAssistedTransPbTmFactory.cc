/*
error_correction package for statistical machine translation
Copyright (C) 2013 Daniel Ortiz-Mart\'inez
 
This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public License
as published by the Free Software Foundation; either version 3
of the License, or (at your option) any later version.
 
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Lesser General Public License for more details.
 
You should have received a copy of the GNU Lesser General Public License
along with this program; If not, see <http://www.gnu.org/licenses/>.
*/
 
/********************************************************************/
/*                                                                  */
/* Module: WgUncoupledAssistedTransPbTmFactory                      */
/*                                                                  */
/* Definitions file: WgUncoupledAssistedTransPbTmFactory.cc         */
/*                                                                  */
/********************************************************************/


//--------------- Include files --------------------------------------

#include "PhrHypNumcovJumps01EqClassF.h"
#include "PbTransModel.h"
#include "WgUncoupledAssistedTrans.h"
#include <string>

//--------------- Function definitions

extern "C" BaseAssistedTrans<PbTransModel<PhrHypNumcovJumps01EqClassF> >* create(const char* /*str*/)
{
  return new WgUncoupledAssistedTrans<PbTransModel<PhrHypNumcovJumps01EqClassF> >;
}

//---------------
extern "C" const char* type_id(void)
{
  return "WgUncoupledAssistedTrans<PbTransModel<PhrHypNumcovJumps01EqClassF> >";
}

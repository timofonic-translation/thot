/*
thot package for statistical machine translation
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
/* Module: PhrHypNumcovJumps01EqClassF                              */
/*                                                                  */
/* Prototypes file: PhrHypNumcovJumps01EqClassF.h                   */
/*                                                                  */
/* Description: Declares the PhrHypNumcovJumps01EqClassF template   */
/*              class, this class is a function object that for     */
/*              each hypothesis returns its equivalence class.      */
/*                                                                  */
/********************************************************************/

/**
 * @file PhrHypNumcovJumps01EqClassF.h
 * 
 * @brief Defines the PhrHypNumcovJumps01EqClassF class, this class is a
 * function object that for each hypothesis returns its equivalence
 * class.
 */

#ifndef _PhrHypNumcovJumps01EqClassF_h
#define _PhrHypNumcovJumps01EqClassF_h

//--------------- Include files --------------------------------------

#if HAVE_CONFIG_H
#  include <thot_config.h>
#endif /* HAVE_CONFIG_H */

#include "PhrHypNumcovJumpsEqClassF.h"

//--------------- Constants ------------------------------------------


//--------------- Classes --------------------------------------------

//--------------- PhrHypNumcovJumps01EqClassF class

/**
 * @brief The PhrHypNumcovJumps01EqClassF class is a function object
 * that for each hypothesis returns its equivalence class.
 */

class PhrHypNumcovJumps01EqClassF: public PhrHypNumcovJumpsEqClassF
{
 public:
  typedef PhrHypNumcovJumpsEqClassF::EqClassType EqClassType;
  typedef PhrHypNumcovJumpsEqClassF::EqClassTypeHashF EqClassTypeHashF;
    
 private:

  void transformRawEqClass(EqClassType &eqc);
};

#endif

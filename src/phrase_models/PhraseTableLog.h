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
/* Module: PhraseTableLog                                           */
/*                                                                  */
/* Prototype file: PhraseTableLog                                   */
/*                                                                  */
/* Description: Implements a bilingual phrase table.                */
/*                                                                  */
/********************************************************************/

#ifndef _PhraseTableLog
#define _PhraseTableLog

//--------------- Include files --------------------------------------

#if HAVE_CONFIG_H
#  include <thot_config.h>
#endif /* HAVE_CONFIG_H */

#include "BasePhraseTable.h"
#include "PhraseDictLog.h"
#include "PhraseCountsLog.h"

//--------------- Constants ------------------------------------------


//--------------- typedefs -------------------------------------------


//--------------- function declarations ------------------------------


//--------------- Classes --------------------------------------------


//--------------- PhraseTableLog class

class PhraseTableLog: public BasePhraseTable
{
 public:

    typedef std::map<std::vector<WordIndex>,PhrasePairInfo> SrcTableNode;
    typedef std::map<std::vector<WordIndex>,PhrasePairInfo> TrgTableNode;

      // Constructor
    PhraseTableLog(void);

        // Abstract function definitions
    virtual void addTableEntry(const std::vector<WordIndex>& s,
                               const std::vector<WordIndex>& t,
                               PhrasePairInfo inf);
    void addTableEntry(const std::vector<WordIndex>& s,
                       const std::vector<WordIndex>& t,
                       LogCount lcs,
                       LogCount lcst);

        // Adds an entry to the probability table
    virtual void addSrcInfo(const std::vector<WordIndex>& s,Count s_inf);
    virtual void addSrcTrgInfo(const std::vector<WordIndex>& s,
                               const std::vector<WordIndex>& t,
                               Count st_inf);
    virtual void incrCountsOfEntry(const std::vector<WordIndex>& s,
                                   const std::vector<WordIndex>& t,
                                   Count c);
    virtual void incrCountsOfEntryLog(const std::vector<WordIndex>& s,
                                      const std::vector<WordIndex>& t,
                                      LogCount lc);
        // Increase the counts of a given phrase pair
    virtual PhrasePairInfo infSrcTrg(const std::vector<WordIndex>& s,
                                     const std::vector<WordIndex>& t,
                                     bool& found);
        // Returns information related to a given s and t.
    virtual Count getSrcInfo(const std::vector<WordIndex>& s,bool &found);
        // Returns information related to a given s and t.
    virtual Count getSrcTrgInfo(const std::vector<WordIndex>& s,
                                const std::vector<WordIndex>& t,
                                bool &found);
        // Returns information related to a given s and t.
    virtual Prob pTrgGivenSrc(const std::vector<WordIndex>& s,
                              const std::vector<WordIndex>& t);
    virtual LgProb logpTrgGivenSrc(const std::vector<WordIndex>& s,
                                   const std::vector<WordIndex>& t);
    virtual Prob pSrcGivenTrg(const std::vector<WordIndex>& s,
                              const std::vector<WordIndex>& t);
    virtual LgProb logpSrcGivenTrg(const std::vector<WordIndex>& s,
                                   const std::vector<WordIndex>& t);
    virtual bool getEntriesForTarget(const std::vector<WordIndex>& t,
                                     SrcTableNode& srctn);
        // Stores in srctn the entries associated to a given target
        // phrase t, returns true if there are one or more entries
    virtual bool getEntriesForTarget(PhraseTableNodeLog* ptnPtr,
                                     SrcTableNode& srctn); 
        // The same as the previous function but a pointer to a
        // PhraseTableNodeLog object is given (which is provided by the
        // nodeForTrgHasOneTransOrMore function)
    virtual bool getEntriesForSource(const std::vector<WordIndex>& s,
                                     TrgTableNode& trgtn);
        // Stores in trgtn the entries associated to a given source
        // phrase s, returns true if there are one or more entries
    virtual bool getNbestForSrc(const std::vector<WordIndex>& s,
                                NbestTableNode<PhraseTransTableNodeData>& nbt);
    virtual bool getNbestForTrg(const std::vector<WordIndex>& t,
                                NbestTableNode<PhraseTransTableNodeData>& nbt,
                                int N=-1);

       // Counts-related functions
    virtual Count cSrcTrg(const std::vector<WordIndex>& s,
                          const std::vector<WordIndex>& t);
    virtual Count cSrc(const std::vector<WordIndex>& s);
    virtual Count cTrg(const std::vector<WordIndex>& t);

    virtual LogCount lcSrcTrg(const std::vector<WordIndex>& s,
                              const std::vector<WordIndex>& t);
    virtual LogCount lcSrc(const std::vector<WordIndex>& s);
    virtual LogCount lcTrg(const std::vector<WordIndex>& t);

        // Additional Functions
    bool nodeForTrgHasAtLeastOneTrans(const std::vector<WordIndex>& t);
        // Returns true if t has one translation or more
    
        // size and clear functions
    virtual size_t size(void);
    virtual void clear(void);   

        // Destructor
    virtual ~PhraseTableLog();

      // const_iterator
    class const_iterator;
    friend class const_iterator;
    class const_iterator
      {
        protected:
           const PhraseTableLog* ptPtr;
           PhraseDictLog::const_iterator pdIter;
           
        public:
           const_iterator(void){ptPtr=NULL;}
           const_iterator(const PhraseTableLog* _ptPtr,
                          PhraseDictLog::const_iterator iter):ptPtr(_ptPtr),pdIter(iter)
             {
             }
           bool operator++(void); //prefix
           bool operator++(int);  //postfix
           int operator==(const const_iterator& right); 
           int operator!=(const const_iterator& right); 
           PhraseDictLog::const_iterator& operator->(void);
      };

        // const_iterator related functions
    PhraseTableLog::const_iterator begin(void)const;
    PhraseTableLog::const_iterator end(void)const;
	
 protected:
	PhraseDictLog phraseDictLog;
    PhraseCountsLog s_LogCounts;

    void getPhraseGivenState(PhraseCountLogState pls_state,
                             std::vector<WordIndex>& s_phrase);
    Count getCountGivenState(PhraseCountLogState pls_state);
    LogCount getSrcLogCount(const std::vector<WordIndex>& s,
                            bool &found);
        // Get log(c(s))
    LogCount getSrcTrgLogCount(const std::vector<WordIndex>& s,
                               const std::vector<WordIndex>& t,
                               bool &found);
        // Get log(c(s,t))

    
    std::pair<bool,PhraseTableNodeLog*>
      nodeForTrgHasOneTransOrMore(const std::vector<WordIndex>& t);
        // Returns true if the target phrase t has one translation or
        // more and a pointer to the corresponding translations

};

#endif

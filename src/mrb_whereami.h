/*
  
**
** See Copyright Notice in LICENSE
*/

#ifndef MRB_WHEREAMI_H
#define MRB_WHEREAMI_H

void mrb_mruby_bin_monolith_gem_init(mrb_state *mrb);
void mrb_mruby_bin_monolith_gem_final(mrb_state *mrb);
const char *whereAmI(void);

#define ML_MODULE           "Monolith"
#define ML_WMI              "whereami"
#define ML_APP_FLAG         "IsApp"

#endif

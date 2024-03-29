#include "ast_statement_comound.h"
#include <string>

std::string CompoundStatement::print()
{
    std::stringstream ss;

    return ss.str();
}

std::string CompoundStatement::cprint()
{
    std::stringstream ss;

    return ss.str();
}

std::string CompoundStatement::codeprint(Context &cont)
{
    std::stringstream ss;
    //ss << Helper::enterNewScope(cont);
    if (dl != NULL)
    {
        ss << dl->codeprint(cont);
    }
    if (sl != NULL)
    {
        ss << sl->codeprint(cont);
        ;
    }
    return ss.str();
}

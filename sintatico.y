%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include "lexico.c"
#include "utils.c"
int contaVar;    // conta o número de variáveis
int contaPar;
int rotulo = 0; // marcar lugares no código 
int tipo;
char escopo;
char atual_func[100];
%}

%token T_PROGRAMA
%token T_INICIO
%token T_FIM
%token T_LEIA
%token T_ESCREVA
%token T_SE
%token T_ENTAO
%token T_SENAO
%token T_FIMSE
%token T_ENQTO
%token T_FACA
%token T_FIMENQTO
%token T_INTEIRO
%token T_LOGICO
%token T_MAIS
%token T_MENOS
%token T_VEZES
%token T_DIV
%token T_MAIOR
%token T_MENOR
%token T_IGUAL
%token T_E
%token T_OU
%token T_NAO
%token T_ATRIBUI
%token T_ABRE
%token T_FECHA
%token T_V
%token T_F
%token T_IDENTIF
%token T_NUMERO

//Acrescentar os tokens para as palavras chaves retorne, func, fimfunc
%token T_RETORNE
%token T_FUNC
%token T_FIMFUNC

%start programa
%expect 1

%left T_E T_OU
%left T_IGUAL
%left T_MAIOR T_MENOR
%left T_MAIS T_MENOS
%left T_VEZES T_DIV

%%

programa 
    : cabecalho
        {contaVar = 0;
            escopo = 'g';
        } 
      variaveis 
        { 
            empilha(contaVar);
            if(contaVar)
                fprintf(yyout,"\tAMEM\t%d\n", contaVar);
        }
        //acrescentar funções
      funcoes
        {
            mostraTabela();
            //int rot = desempilha();
            //fprintf(yyout,"L%d\tNADA\n", rot); 

        }
      T_INICIO lista_comandos T_FIM
        { 
            int conta = desempilha();
            if(conta)
                fprintf(yyout,"\tDMEM\t%d\n", conta);
            fprintf(yyout, "\tFIMP\n"); 
        }
    ;

cabecalho
    : T_PROGRAMA T_IDENTIF
        { fprintf(yyout,"\tINPP\n"); }
    ;

variaveis
    : /* vazio */
    | declaracao_variaveis
    ;

declaracao_variaveis
    : tipo lista_variaveis declaracao_variaveis
    | tipo lista_variaveis
    ;

tipo
    : T_LOGICO
        { tipo = LOG; }
    | T_INTEIRO
        { tipo = INT; }
    ;

lista_variaveis
    : lista_variaveis T_IDENTIF 
        {
            strcpy(elemTab.id, atomo);
            elemTab.end = contaVar;
            elemTab.tip = tipo;
            elemTab.cat = 'v';
            elemTab.esc = escopo;
            insereSimbolo(elemTab);
            contaVar++;
            
        }
    | T_IDENTIF
        {
            strcpy(elemTab.id, atomo);
            elemTab.end = contaVar;
            elemTab.tip = tipo;
            elemTab.cat = 'v';
            elemTab.esc = escopo;
            insereSimbolo(elemTab);
            contaVar++;
        }
    ;


    /* REGRAS PARA AS FUNÇÕES */
funcoes
    : /* vazio */
    | funcao funcoes 
    ;

funcao
    : T_FUNC tipo T_IDENTIF 
      {
        fprintf(yyout,"\tDSVS\tL%d\n", rotulo);
        empilha(rotulo);
        contaPar = 0;
        strcpy (elemTab.id, atomo);
        strcpy (atual_func, atomo);
        elemTab.cat = 'f';
        elemTab.esc = escopo;
        elemTab.tip = tipo;
        elemTab.rot = ++rotulo;
        insereSimbolo(elemTab);
        fprintf(yyout, "L%d\tENSP\n", rotulo);
        empilha(rotulo); 

        escopo = 'l';
      }
    
      T_ABRE lista_parametros T_FECHA 
        //chamar uma rotina para ajustar os parametros no vetor (negativo, contar o número de parametros)
        {
            ajusta_parametros(contaPar);

        }
        //passou pelo fecha colocar os endereços (-5, -4, -3)
      variaveis T_INICIO lista_comandos T_FIMFUNC
      // similar a declaração em variaveis já feita :
      /*    empilha(contaVar);
            if(contaVar)
                fprintf(yyout,"\tAMEM\t%d\n", contaVar);*/
      //remover variaveis locais e parametros
      {
        //remover_variaveis();
        escopo = 'g';
      }
    ;

lista_parametros
    :/* vazio */
    | parametro lista_parametros
    ;

parametro
    : tipo T_IDENTIF
      {
        strcpy(elemTab.id, atomo);
        elemTab.tip = tipo;
        elemTab.cat = 'p';
        elemTab.esc = escopo;
        contaPar++;
        insereSimbolo(elemTab); 
        /* Chamada de função para coloca o parametro dentro do vetor de parametros da função */
        coloca_parametro(contaPar,tipo, atual_func);  
      }
    ;

lista_comandos
    : /* vazio */
    | comando lista_comandos
    ;

comando
    : entrada_saida
    | repeticao
    | selecao
    | atribuicao
    | retorno
    ;

retorno
    :T_RETORNE expressao
        //deve gerar (depois da tradução da expressão)
        // comparar se o tipo da função é compatível (retorno é compativel com a declaração??)
        // ARZL y(valor de retorno),  --> y =  endereço de retorno --> endereço do nome da função na tabela (ex -5)
        //DMEM x (se tiver variavel local) --> x = quantidade de variáveis
        //RTSP n --> n = quantidade de parametro
    ;

entrada_saida
    : leitura
    | escrita
    ;

leitura
    :T_LEIA T_IDENTIF
        {
            int pos = buscaSimbolo(atomo);
            fprintf(yyout,"\tLEIA\n\tARZG\t%d\n", tabSimb[pos].end); 
        }
    ;

escrita
    : T_ESCREVA expressao
        { 
            desempilha();
            fprintf(yyout,"\tESCR\n"); 
        }
    ;

repeticao
    : T_ENQTO
        { 
            fprintf(yyout,"L%d\tNADA\n", ++rotulo); 
            empilha(rotulo);
        } 
      expressao T_FACA 
        { 
            int tip = desempilha();
            if(tip != LOG)
                yyerror("Incompatibilidade de tipo!");
            fprintf(yyout,"\tDSVF\tL%d\n", ++rotulo);
            empilha(rotulo); 
        }  
      lista_comandos 
      T_FIMENQTO
        { 
            int rot1 = desempilha();
            int rot2 = desempilha();
            fprintf(yyout,"\tDSVS\tL%d\n", rot2); 
            fprintf(yyout,"L%d\tNADA\n", rot1); 

        }
    ;

selecao
    : T_SE expressao T_ENTAO
        { 
            int tip = desempilha();
            if(tip != LOG)
                yyerror("Incompatibilidade de tipo!");
            fprintf(yyout,"\tDSVF\tL%d\n", ++rotulo); 
            empilha(rotulo);
            //printf("rot1 = %d\n ", rotulo);
        }
      lista_comandos T_SENAO
        { 
            int rot = desempilha();
            //printf("rot2 = %d\n ", rot);
            fprintf(yyout,"\tDSVS\tL%d\n", ++rotulo); 
            fprintf(yyout, "L%d\tNADA\n", rot);
            empilha(rotulo);
        } 
      lista_comandos T_FIMSE
        { 
            int rot = desempilha();
            //printf("rot3 = %d\n ", rot);
            fprintf(yyout,"L%d\tNADA\n",rot ); 
        }
    ;

atribuicao
    : T_IDENTIF 
        {
            int pos = buscaSimbolo(atomo);
            empilha(pos);
        }
      T_ATRIBUI expressao
        {
            int tip = desempilha();
            int pos = desempilha();
            if(tabSimb[pos].tip != tip)
                yyerror("Incompatibilidade de tipo!");
            fprintf(yyout,"\tARZG\t%d\n", tabSimb[pos].end); 
        }
    ;

expressao
    : expressao T_VEZES expressao
        { 
            testaTipo(INT, INT, INT);
            fprintf(yyout,"\tMULT\n"); 
        }
    | expressao T_DIV expressao
        { 
            testaTipo(INT, INT, INT);
            fprintf(yyout,"\tDIVI\n"); 
        }
    | expressao T_MAIS expressao
        { 
            testaTipo(INT, INT, INT);
            fprintf(yyout,"\tSOMA\n"); 
        }
    | expressao T_MENOS expressao
        { 
            testaTipo(INT, INT, INT);
            fprintf(yyout,"\tSUBT\n"); 
        }
    | expressao T_MAIOR expressao
        { 
            testaTipo(INT, INT, LOG);
            fprintf(yyout,"\tCMMA\n"); 
        }
    | expressao T_MENOR expressao
        { 
            testaTipo(INT, INT, LOG);
            fprintf(yyout,"\tCMME\n"); 
        }
    | expressao T_IGUAL expressao
        { 
            testaTipo(INT, INT, LOG);
            fprintf(yyout,"\tCMIG\n"); 
        }
    | expressao T_E expressao
        { 
            testaTipo(LOG, LOG, LOG);
            fprintf(yyout,"\tCONJ\n"); 
        }
    | expressao T_OU expressao
        { 
            testaTipo(LOG, LOG, LOG);
            fprintf(yyout,"\tDISJ\n"); 
        }
    | termo
    ;

identificador
    : T_IDENTIF
        { 
            int pos = buscaSimbolo(atomo);
            empilha(tabSimb[pos].tip);
        }
    ;

// A função é chamada como um termo numa expressão
chamada 
    : /* Sem parenteses indica que é uma variável */
    // gerar o código mas tem q testar se é global ou local
        {
            if(escopo = 'g'){
                /* É uma variável Global */
            }else{
                /* É uma variável Local */
            }
        }
    //colocar gerar código de variavel
    | T_ABRE lista_argumentos T_FECHA
    // gerar AMEM
    ;

lista_argumentos
    :/* vazio */
    | expressao  lista_argumentos
    ;
    
termo
    : identificador chamada 
    /*: T_IDENTIF
        { 
            int pos = buscaSimbolo(atomo);
            fprintf(yyout,"\tCRVG\t%d\n", tabSimb[pos].end); 
            empilha(tabSimb[pos].tip);
        }*/
    | T_NUMERO
        { 
            fprintf(yyout,"\tCRCT\t%s\n", atomo); 
            empilha(INT);
        }
    | T_V
        { 
            fprintf(yyout,"\tCRCT\t1\n"); 
            empilha(LOG);
        }
    | T_F
        { 
            fprintf(yyout,"\tCRCT\t0\n"); 
            empilha(LOG);
        }
    | T_NAO termo
        { 
            int t = desempilha();
            if(t != LOG) yyerror ("Incompatibilidade de tipo!");
            fprintf(yyout,"\tNEGA\n");
            empilha(LOG);

        }
    | T_ABRE expressao T_FECHA
    ;

%%

int main (int argc, char *argv[]){
    char *p, nameIn[100], nameOut[100];
    argv++;
    if(argc < 2){
        puts("\nCompilador Simples");
        puts("\n\tUso: ./simples <NOME>[.simples]\n\n");
        exit(10);
    }
    p = strstr(argv[0], ".simples");
    if(p) *p = 0;
    strcpy(nameIn, argv[0]);
    strcat(nameIn, ".simples");
    strcpy(nameOut, argv[0]);
    strcat(nameOut, ".mvs");
    yyin = fopen (nameIn, "rt");
    if(!yyin){
        puts("Programa fonte não encontrado!");
        exit(20);
    }
    yyout = fopen(nameOut, "wt");
    yyparse();
    puts ("Programa OK!");
}
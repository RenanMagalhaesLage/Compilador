%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include "lexico.c"
#include "utils.c"
int contaVar=0;    // conta o número de variáveis
int contaPar;
int rotulo = 0; // marcar lugares no código 
int tipo;
char escopo;
char atual_func[100];   //Guarda nome da ultima função declarada
int posFunc;            //Guarda posição na tabela de símbolo
char chama_func[100];   //Guarda o nome da chamada da função
//int numChamadaPar = 0;      //Guarda a quantidade de parametros que foi usada na chamada --> serve para verificar se está correto
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
        {
            contaVar = 0;
            escopo = 'g';
        } 
      variaveis 
        { 
            empilha(contaVar, 'n');
            if(contaVar)
                fprintf(yyout,"\tAMEM\t%d\n", contaVar);
            contaVar = 0;
        }
        /*Acrescenta Rotinas/Funções*/
      rotinas
        {

            //printf("id = %s esc = %c", tabSimb[4].id,tabSimb[4].esc);
            mostraTabela();
            //int rot = desempilha();
            //fprintf(yyout,"L%d\tNADA\n", rot); 

        }
      T_INICIO 
      lista_comandos 
      T_FIM
        { 
            int conta = finalPilha();
            //int conta = desempilha('n');
            if(conta)
                fprintf(yyout,"\tDMEM\t%d\n", conta);
            fprintf(yyout, "\tFIMP\n"); 
            mostrapilha();
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

rotinas
    :/* NÃO TEM FUNÇÕES */
    |
    {
        fprintf(yyout,"\tDSVS\tL0\n");
    }
    funcoes
    {
        fprintf(yyout,"L0\tNADA\n");
    }
    ;

    /* REGRAS PARA AS FUNÇÕES */
funcoes
    : funcao
    | funcao funcoes 
    ;

funcao
    : T_FUNC tipo T_IDENTIF 
      {
        contaPar = 0;
        strcpy (elemTab.id, atomo);
        strcpy (atual_func, atomo);
        elemTab.cat = 'f';
        elemTab.esc = escopo;
        elemTab.tip = tipo;
        elemTab.rot = ++rotulo;
        insereSimbolo(elemTab);
        fprintf(yyout, "L%d\tENSP\n", rotulo);
        empilha(rotulo, 'r'); 

        escopo = 'l';
      }
    
      T_ABRE lista_parametros T_FECHA 
        //chamar uma rotina para ajustar os parametros no vetor (negativo, contar o número de parametros)
        {
            //Tem que empilhar:
            //num de var locais
            //endereço de retorno
            //numero de parametro
            empilha(contaPar, 'n');
            //ajusta_parametros(contaPar);
            ajusta_parametros2(atual_func);
            //printf("par = %d func = %s\n",contaPar,atual_func);
            int end = buscaFunc(atual_func);
            empilha(end, 'p');

        }
        //passou pelo fecha colocar os endereços (-5, -4, -3)
      variaveis 
      {
        empilha(contaVar,'n');
        //printf("contarVar = %d", contaVar);
        if(contaVar)
            fprintf(yyout,"\tAMEM\t%d\n", contaVar);
        contaVar = 0;
      }
      T_INICIO lista_comandos T_FIMFUNC
      // similar a declaração em variaveis já feita :
      /*    empilha(contaVar);
            if(contaVar)
                fprintf(yyout,"\tAMEM\t%d\n", contaVar);*/
      //remover variaveis locais e parametros
      {
        mostraTabela();
        remover_tabela();
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
        //AQUI ESTÁ COM PROBLEMA
        elemTab.esc = escopo;
        //printf("esc = %c",escopo);
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
    {
        int tipo = desempilha('t');
        //int teste = desempilha('r');
        //int x  = desempilha('n');
        //int y = desempilha('p');
        //printf("atomo = %s\n",atomo);
        //int y = buscaFunc(chama_func);
        //printf("atomo = %s y = %d\n",atual_func,y);

        int end = buscaPilha('p');
        //printf("end = %d\n",end);

        //ARZL y (valor de retorno)         --> y =  endereço de retorno --> endereço do nome da função na tabela (ex -5)
        //DMEM x (se tiver variavel local)  --> x = quantidade de variáveis locais
        //RTSP n                            --> n = quantidade de parametro
        fprintf(yyout,"\tARZL\t%d\n",end);
        if(contaVar !=0){
            fprintf(yyout,"\tDMEM\t%d\n", contaVar); 
        } 
        fprintf(yyout,"\tRTSP\t%d\n",contaPar);
    }

        //deve gerar (depois da tradução da expressão)
        // comparar se o tipo da função é compatível (retorno é compativel com a declaração??)
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
            desempilha('t');
            fprintf(yyout,"\tESCR\n"); 
        }
    ;

repeticao
    : T_ENQTO
        { 
            fprintf(yyout,"L%d\tNADA\n", ++rotulo); 
            empilha(rotulo, 'r');
        } 
      expressao T_FACA 
        { 
            int tip = desempilha('t');
            if(tip != LOG)
                yyerror("Incompatibilidade de tipo!");
            fprintf(yyout,"\tDSVF\tL%d\n", ++rotulo);
            empilha(rotulo,'r'); 
        }  
      lista_comandos 
      T_FIMENQTO
        { 
            int rot1 = desempilha('r');
            int rot2 = desempilha('r');
            fprintf(yyout,"\tDSVS\tL%d\n", rot2); 
            fprintf(yyout,"L%d\tNADA\n", rot1); 

        }
    ;

selecao
    : T_SE expressao T_ENTAO
        { 
            int tip = desempilha('t');
            if(tip != LOG)
                yyerror("Incompatibilidade de tipo!");
            fprintf(yyout,"\tDSVF\tL%d\n", ++rotulo); 
            empilha(rotulo,'r');
        }
      lista_comandos T_SENAO
        { 
            int rot = desempilha('r');
            fprintf(yyout,"\tDSVS\tL%d\n", ++rotulo); 
            fprintf(yyout, "L%d\tNADA\n", rot);
            empilha(rotulo,'r');
        } 
      lista_comandos T_FIMSE
        { 
            int rot = desempilha('r');
            fprintf(yyout,"L%d\tNADA\n",rot ); 
        }
    ;

atribuicao
    : T_IDENTIF 
        {
            int pos = buscaSimbolo(atomo);
            empilha(pos,'p');
        }
      T_ATRIBUI expressao
        {
            int tip = desempilha('t');
            int pos = desempilha('p');
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
            strcpy(chama_func, atomo);
            int pos = buscaSimbolo(atomo);
            empilha(pos,'p');
        }
    ;

// A função é chamada como um termo numa expressão
chamada 
    : /* Sem parenteses indica que é uma variável */
    /* Testar se é global ou local*/
        {
            int pos = desempilha('p');
            //int pos = buscaSimbolo(atomo);
            if(tabSimb[pos].esc == 'g'){
                /* É uma variável Global */
                fprintf(yyout,"\tCRVG\t%d\n", tabSimb[pos].end); 
                empilha(tabSimb[pos].tip,'t');
            }else{
                /* É uma variável Local */
                fprintf(yyout,"\tCRVL\t%d\n", tabSimb[pos].end); 
                empilha(tabSimb[pos].tip,'t');
            }
        }
    | T_ABRE 
        /*Gerar AMEM */
        {
            int pos = desempilha('p');
            posFunc = pos;
            empilha(tabSimb[pos].tip, 't');
            fprintf(yyout,"\tAMEM\t1\n");
        }
      lista_argumentos 
      T_FECHA
      {
        /*Gerar SVCP e DSVS */
        //empilha(posFunc, 'p');
        //int pos = desempilha('p');
        fprintf(yyout,"\tSVCP\n"); 
        fprintf(yyout,"\tDSVS\tL%d\n",tabSimb[posFunc].rot); 
        int y = qntParChamada();
        //printf("par = %d\n", y);
        int x = desempilha('t');
        /*Chama a função para verificar se houve algum ERRO*/
        comparaSeERRO(chama_func, y, x);
        empilha(x,'t');
      }

    ;

lista_argumentos
    :/* vazio */
    | expressao  
    {
        //int tipo = desempilha('t');
        //numChamadaPar++;


    }
    lista_argumentos
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
            empilha(INT,'t');
        }
    | T_V
        { 
            fprintf(yyout,"\tCRCT\t1\n"); 
            empilha(LOG, 't');
        }
    | T_F
        { 
            fprintf(yyout,"\tCRCT\t0\n"); 
            empilha(LOG,'t');
        }
    | T_NAO termo
        { 
            int t = desempilha('t');
            if(t != LOG) yyerror ("Incompatibilidade de tipo!");
            fprintf(yyout,"\tNEGA\n");
            empilha(LOG,'t');

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
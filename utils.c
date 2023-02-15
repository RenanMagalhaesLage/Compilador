// Estrutura da Tabela de Símbolos
#include "ctype.h"  //<ctype.h>
#include <string.h>
#define TAM_TAB 100
#define MAX_PAR 20
enum {INT, LOG};

struct elemTabSimbolos
{
    char id[100];               //Identificador
    int end;                    //Endereço (Global) ou  deslocamento (Local)
    char cat;                   //Categoria --> 'f'= FUN, 'p' = PAR, 'v' = VAR
    int tip;                    //Tipo
    char esc;                   //Escopo --> 'g' = global e 'l' = local
    int rot;                    //Rótulo (Específico para a função)
    int par[MAX_PAR];           //Vetor de parâmetros --> guarda apenas o TIPO do parâmetro
    int qntPar;                 //Quantidade de parâmetros --> quantos campos do vetor estão sendo utilizados    

}tabSimb[TAM_TAB],elemTab;

int posTab = 0;

void maiuscula (char *s){
    for(int i = 0; s[i]; i++){
        s[i] = toupper(s[i]);
    }
}

int buscaSimbolo(char *id){
    int i;
    //maiuscula(id);
    for (i = posTab - 1; strcmp(tabSimb[i].id, id) && i >=0; i--)
        ;
    if (i == -1){
        char msg[200];
        sprintf(msg, "Identificador [%s] não encontrado!", id);
        yyerror(msg);
    }
    return i;
}

void insereSimbolo (struct elemTabSimbolos elem){
    int i;
    //maiuscula(elem.id);
    if (posTab == TAM_TAB)
        yyerror("Tabela de Simbolos Cheia");
    /* Comparação para possibilitar a declaração de variáveis Globais e Locais com o mesmo nome */
    for (i = posTab - 1; (strcmp(tabSimb[i].id, elem.id) || tabSimb[i].esc != elem.esc)&& i >=0; i--)
        ;
    if (i != -1){
        char msg[200];
        sprintf(msg, "Identificador [%s] duplicado!", elem.id);
        yyerror(msg);
    }
    tabSimb[posTab++] = elem;
}

void mostraTabela(){
    puts("\nTabela de Simbolos");
    for(int i = 0; i < 60; i++){
        printf("-");
    }
    printf("\n");
    printf("%8s | %s | %s | %s | %s | %s | %s | %s\n", "ID", "END", "CAT", "TIP", "ESC", "ROT", "QNT", "PAR");
    for(int i = 0; i < 60; i++){
        printf("-");
    }
    for(int i = 0; i < posTab; i++ ){
        printf("\n%8s | %3d | %3c | %s | %3c | %3d | %3d |", tabSimb[i].id, tabSimb[i].end, tabSimb[i].cat, tabSimb[i].tip == INT? "INT" : "LOG", tabSimb[i].esc, tabSimb[i].cat == 'f'? tabSimb[i].rot: -1, tabSimb[i].cat == 'f'? tabSimb[i].qntPar: -1 );
        if(tabSimb[i].cat == 'f'){
            int qnt = tabSimb[i].qntPar;            
            printf("[ ");
            for(int j = 0; j < qnt; j++){
                printf(" %s ", tabSimb[i].par[j] == INT? "INT" : "LOG");
            }
            printf(" ]");
        }
    }
    printf("\n");
    for(int i = 0; i < 60; i++){
        printf("-");
    }
    printf("\n");
}

//Sugestão: Desenvolver uma rotina para ajustar o endereço dos parametros na tabela de símbolos e o vetor de 
//parametros da função depois que for cadastrado o ultimo parametro

/* Função para ajustar o endereço dos parametros  */
/* NÃO UTILIZADA*/
void ajusta_parametros(int qnt_Par){
    for(int i = 0; i < posTab ; i++){
        if (tabSimb[i].cat == 'p' ||tabSimb[i].cat == 'f' )
        {
            if(tabSimb[i].cat == 'f'){
                tabSimb[i].qntPar = qnt_Par;
                /*for(int j=0; j < qnt_Par; j ++){
                    int tip = desempilha('t');
                    tabSimb[i].par[qnt_Par-1] = tip;
                    qnt_Par--;
                }*/
            }
            tabSimb[i].end = (-3) - (qnt_Par);
            qnt_Par--;
        }
    }
}

/* Função para colocar os parametros dentro do vetor de parametros da função */
void coloca_parametro(int qnt_Par,int tipo, char nome_func[100]){
    for(int i = 0; i < posTab ; i++){
        if(tabSimb[i].cat == 'f' && !strcmp(tabSimb[i].id, nome_func)){
            tabSimb[i].par[qnt_Par-1] = tipo;
        }

    }
}

int buscaFunc(char *nome_func){
    for(int i=0; i < posTab; i++){
        if(tabSimb[i].cat == 'f' && (!strcmp(tabSimb[i].id, nome_func))){
            //printf("end = %d func = %s\n",tabSimb[i].end,tabSimb[i].id );
            return (tabSimb[i].end);
        }
    }
}


/*=============================================================
                Estruturada Pilha Semantica
        usada para enderecos, variaveis, rotulos

===============================================================*/

#define TAM_PIL 100
struct 
{
    int valor;
    char tipo;  // r = rotulo , n = numero de variaveis, t = tipo p = posicao
}pilha[TAM_PIL];

//int pilha[TAM_PIL];
int topo = -1;

void mostrapilha(){
    int i = topo;
    printf("Pilha = [ ");
    while(i>=0){
        printf(" (%d,%c) ", pilha[i].valor, pilha[i].tipo);
        i--;
    }
    printf(" ]\n");
}

void empilha (int valor, char tipo){
    if (topo == TAM_PIL)
        yyerror("Pilha semântica cheia");
    pilha[++topo].valor = valor;
    pilha[topo].tipo = tipo;
}

int desempilha(char tipo){
    if(topo == -1)
        yyerror("Pilha semântica vazia!!");
    if(pilha[topo].tipo != tipo){
        char msg[100];
        mostrapilha();
        sprintf(msg, "Desempilha esperado [%c], encontrado [%c]", tipo, pilha[topo].tipo);
        yyerror(msg);
    }
    return pilha[topo--].valor; 
}



void testaTipo(int tipo1, int tipo2, int ret){
    int t1 = desempilha('t');
    int t2 = desempilha('t');
    if(t1 != tipo1 || t2 != tipo2) 
        yyerror ("Incompatibilidade de tipo!");
    empilha(ret,'t');
}

/*Conta a quantidade de parametros da chamada da função*/
int qntParChamada(){
    int numChamadaPar=0;
    int pos = topo;
    while(pilha[pos].tipo == 't'){
        numChamadaPar++;
        pos--;
    }    
    return (numChamadaPar-1);

}

/*Função para Retornar Erro das funções*/
int comparaSeERRO(char *nome_func,int qntPar, int tipo){
    char msg[100];
    for(int i=0; i < posTab; i++){
        if(tabSimb[i].cat == 'f' && !strcmp(tabSimb[i].id, nome_func)){
            int tamanho = tabSimb[i].qntPar;
            /*ERRO - Incompatibilidade de tipo de parametro*/
            for(int j = 0; j < tamanho; j++)
            {   
                int x = desempilha('t');
                if(tabSimb[i].par[tamanho-1] != x)
                {
                    sprintf(msg, "Incompatibilidade de tipo! Esperava [%s], recebeu [%s]", tabSimb[i].par[tamanho-1] == INT? "INT" : "LOG", x == INT? "INT" : "LOG" );
                    yyerror(msg);
                }
            }
            
            /*ERRO - Incompatibilidade de quantidade de parametros*/
            if(tabSimb[i].qntPar != qntPar)
            {
                sprintf(msg, "Incompatibilidade na quantidade de parametros! Esperava [%d], recebeu [%d]", tabSimb[i].qntPar, qntPar);
                yyerror(msg);
            }
            /*ERRO - Incompatibilidade de tipo de função*/
            if(tabSimb[i].tip != tipo)
            {
                sprintf(msg, "Incompatibilidade de tipo da função! Esperava [%s], recebeu [%s]", tabSimb[i].tip == INT? "INT" : "LOG", tipo == INT? "INT" : "LOG");
                yyerror(msg);
            }

        }
    }
}

int buscaPilha(char busca){
    int pos = topo;
    while(pilha[pos].tipo != busca){
        pos--;
    }
    return pilha[pos].valor;
}

void ajusta_parametros2(char *nome_func){
    int numPar = desempilha('n');
    empilha(numPar,'n');
    int param = numPar;
    int i = 0;
    while(i < posTab){
        if (!strcmp(tabSimb[i].id, nome_func))
        {
            if(tabSimb[i].cat == 'f'){
                tabSimb[i].qntPar = numPar;
                tabSimb[i].end = (-3) - (param);
                param--;
            }
            while(param >= 0)
            {
                i++;
                tabSimb[i].end = (-3) - (param);
                param--;
            }
        }
        i++;
    }
    
}

/* Função para remover elementos locais da tabela */
/* Apenas diminui a posição da tabela para que assim possa ser sobreescrita*/
void remover_tabela(){
    //printf("posTab = %d\n",posTab);
    int cont = 0;
    int posicao = posTab;
    for(int i = 0; i < posTab ; i++){
        if(tabSimb[i].esc != 'g'){
            cont++;
        }
    }
    posTab = posTab - cont;
}

/* Função para retornar o primeiro elemento colocado na pilha - Esse elemento é o número de variáveis GLOBAIS do programa*/
int finalPilha(){
    return pilha[0].valor;
}

/* Função para desempilhar tipo na pilha - útil na parte de retorno*/
void verifica_topo(){
    if(pilha[topo].tipo == 't'){
        desempilha('t');
        verifica_topo();
    }
}

/*
void testaAritmetico(){
    int t1 = desempilha();
    int t2 = desempilha();
    if(t1 != INT || t2 != INT) 
        yyerror ("Incompatibilidade de tipo!");
    empilha(INT);
}

void testaRelacional(){
    int t1 = desempilha();
    int t2 = desempilha();
    if(t1 != INT || t2 != INT) 
        yyerror ("Incompatibilidade de tipo!");
    empilha(LOG);
}

void testaLogico(){
    int t1 = desempilha();
    int t2 = desempilha();
    if(t1 != LOG || t2 != LOG) 
        yyerror ("Incompatibilidade de tipo!");
    empilha(LOG);
}
*/




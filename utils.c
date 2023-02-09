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
}

//Sugestão: Desenvolver uma rotina para ajustar o endereço dos parametros na tabela de símbolos e o vetor de 
//parametros da função depois que for cadastrado o ultimo parametro

/* Função para ajustar o endereço dos parametros  */

void ajusta_parametros(int qnt_Par){
    for(int i = 0; i < posTab ; i++){
        if (tabSimb[i].cat == 'p' ||tabSimb[i].cat == 'f' )
        {
            if(tabSimb[i].cat == 'f'){
                tabSimb[i].qntPar = qnt_Par;
            }
            tabSimb[i].end = (-3) - (qnt_Par);
            qnt_Par--;
        }
    }
}

/* Função para colocar os parametros dentro do vetor de parametros da função */

void coloca_parametro(int qnt_Par,int tipo, char nome_func[100]){
    for(int i = 0; i < posTab ; i++){
        if(tabSimb[i].cat == 'f' || strcmp(tabSimb[i].id, nome_func)){
            tabSimb[i].par[qnt_Par-1] = tipo;
        }

    }
}

// Estruturada Pilha Semantica
// usada para enderecos, variaveis, rotulos

#define TAM_PIL 100
int pilha[TAM_PIL];
int topo = -1;

void empilha (int valor){
    if (topo == TAM_PIL)
        yyerror("Pilha semântica cheia");
    pilha[++topo] = valor;
}
int desempilha(){
    if(topo == -1)
        yyerror("PIlha semântica vazia!!");
    return pilha[topo--]; 
}

void testaTipo(int tipo1, int tipo2, int ret){
    int t1 = desempilha();
    int t2 = desempilha();
    if(t1 != tipo1 || t2 != tipo2) 
        yyerror ("Incompatibilidade de tipo!");
    empilha(ret);
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




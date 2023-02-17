#### Universidade Federal de Alfenas - UNIFAL-MG
Bacharelado em Ciência da Computação

Prof. [Luiz Eduardo da Silva](https://github.com/luizedsilva)

<hr>
<div align="center">
<h1>Trabalho de Compiladores</h1>
    <p>Função com retorno</p>
    <p>Trabalho realizado na disciplina: Teoria de Linguagens e Compiladores </p>
</div>

## Objetivo
O objetivo desse trabalho  é modificar o projeto do compilador para linguagem simples a fim
de permitir a compilação de funções no estilo da linguagem C, com múltiplos pontos de saída
da função, através do comando retorne.

## Problema
A função, nas linguagens de programação, é um pedaço de código que pode ser invocado em
qualquer lugar do programa com o uso do nome da função. Valores podem ser passados através
dos parâmetros e o resultado da função é devolvido na expressão em que a função foi chamada.
Linguagens de programação no estilo de Pascal (Pascal-like) usam um mecanismo de retorno
do resultado através da variável-nome-da-função, conforme foi apresentado nos exemplos da
linguagem Simples. A atribuição, dentro da função, para a variável-nome-da-função define o
valor que será retornado da chamada da função, quando a função  é finalizada.
As linguagens C-like implementam um mecanismo diferente. Existe o comando return expressao que pode ser colocado em qualquer 
ponto da função e determina sua saída com o valor da expressão. Diferente do mecanismo Pascal-like, nas linguagens parecidas com C é possível
múltiplos pontos de saída da função.

## Roteiro
1. Defina regras para permitir a declaração de funções, conforme o seguinte exemplo:
```bash
func inteiro MAIOR ( inteiro A inteiro B)
inicio
    se A > B
        entao retorne A
        senao retorne B
    fimse
fimfunc
```

2. Defina a palavra-reservada retorne, no léxico, e um comando retorne expressao, no sintático,
que só pode ser usado no contexto da função (em C isso não é necessário, pois o corpo
principal do código está numa função denominada main).
3. Considere que a função só admite parâmetros passados por valor.
4. O compilador deve verificar compatibilidade no tipo da função, no número e tipo dos
parâmetros na chamada da função.
5. O compilador deve ser capaz de produzir as traduções conforme os exemplos fornecidos.

## Execução
```bash
make
```

```bash
./simples nome
```

```bash
./mvs nome
```

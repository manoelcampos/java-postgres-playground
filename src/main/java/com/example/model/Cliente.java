package com.example.model;

import java.time.LocalDate;

public class Cliente {
    private String nome;
    private int anoNascimento;
    private char sexo;
    private String cidade;
    private boolean especial;

    public Cliente(){
        this.especial = Math.random() > 0.5;
    }

    public boolean isEspecial() {
        return especial;
    }

    public String getNome() {
        return nome;
    }
    public void setNome(String nome) {
        this.nome = nome;
    }
    public int getAnoNascimento() {
        return anoNascimento;
    }
    public void setAnoNascimento(int anoNascimento) {
        this.anoNascimento = anoNascimento;
    }
    public char getSexo() {
        return sexo;
    }
    public void setSexo(char sexo) {
        this.sexo = sexo;
    }
    public String getCidade() {
        return cidade;
    }
    public void setCidade(String cidade) {
        this.cidade = cidade;
    }    

    public int idade(){
        return LocalDate.now().getYear() - anoNascimento;
    }
    
}

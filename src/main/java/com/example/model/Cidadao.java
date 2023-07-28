package com.example.model;

import java.time.LocalDate;

public class Cidadao {
    private String nome;
    private LocalDate dataNascimento;

    public int idade(){
        return LocalDate.now().getYear() - dataNascimento.getYear();
    }

    public String eleitor(){
        int idade = idade();
        if(idade < 16)
            return "Não eleitor";
        
        if(idade >= 16 && idade < 18 || idade > 70)
            return "Eleitor facultativo";

        return "Eleitor Obrigatório";
    }

    public String getNome() {
        return nome;
    }
    public void setNome(String nome) {
        this.nome = nome;
    }
    public LocalDate getDataNascimento() {
        return dataNascimento;
    }
    public void setDataNascimento(LocalDate dataNascimento) {
        this.dataNascimento = dataNascimento;
    }
}

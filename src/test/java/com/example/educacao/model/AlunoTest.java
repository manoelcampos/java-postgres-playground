package com.example.educacao.model;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

public class AlunoTest {
    @Test
    void calculaMediaComErroDePrecisao(){
        var aluno = new Aluno();
        aluno.setNota1(10);
        aluno.setNota2(8);
        aluno.setNota3(8);
        double esperado = 8.66;
        double obtido = aluno.calculaMedia();
        assertEquals(esperado, obtido, 0.01);
    }

    @Test
    void calculaMediaValoresIguais(){
        var aluno = new Aluno();
        aluno.setNota1(10);
        aluno.setNota2(10);
        aluno.setNota3(10);
        double esperado = 10;
        double obtido = aluno.calculaMedia();
        assertEquals(esperado, obtido, 0.01);
    }
}

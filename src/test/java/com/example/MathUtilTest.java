package com.example;

import static org.junit.jupiter.api.Assertions.*;

import org.junit.jupiter.api.Test;
import static com.example.MathUtil.mdc;

public class MathUtilTest {
    @Test
    void testMdcP1BImpar() {
        int a = 6, b = 3;
        int esperado = 3;
        int obtido = mdc(a, b);

        assertEquals(esperado, obtido);
    }

    @Test
    void testMdcP1BPar() {
        int a = 6, b = 2;
        int esperado = 2;
        int obtido = mdc(a, b);

        assertEquals(esperado, obtido);
    }

    @Test
    void testMdcP3Negativo() {
        int a = -6, b = 0;
        int esperado = 6;
        int obtido = mdc(a, b);

        assertEquals(esperado, obtido);
    }

    @Test
    void testMdcP3Positivo() {
        int a = 6, b = 0;
        int esperado = 6;
        int obtido = mdc(a, b);

        assertEquals(esperado, obtido);
    }

    @Test
    void testMdcP5Crescente() {
        int a = 2, b = 6;
        int esperado = mdc(b, a);
        int obtido = mdc(a, b);

        assertEquals(esperado, obtido);
    }

    @Test
    void testMdcP5Descrescente() {
        int a = 6, b = 2;
        int esperado = mdc(b, a);
        int obtido = mdc(a, b);

        assertEquals(esperado, obtido);
    }

    @Test
    void testMdcP7() {
        int a = 6, b = 2;
        int esperado = mdc(-a, b);
        int obtido = mdc(-a, -b);

        assertEquals(esperado, obtido);
    }

    @Test
    void testMdcP8Par() {
        int a = 6;
        int esperado = 6;
        int obtido = mdc(a, a);

        assertEquals(esperado, obtido);
    }

    @Test
    void testMdcP8Negativo() {
        int a = -6;
        int esperado = 6;
        int obtido = mdc(a, a);

        assertEquals(esperado, obtido);
    }

    @Test
    void testMdcP12DoisPrimos() {
        int p = 7, a = p;
        int esperado = p;
        int obtido = mdc(p, a);

        assertEquals(esperado, obtido);
    }

    @Test
    void testMdcP12UmPrimo() {
        int p = 7, a = 2;
        int esperado = 1;
        int obtido = mdc(p, a);

        assertEquals(esperado, obtido);
    }

    @Test
    void testMdcP12PrimoEUm() {
        int p = 7, a = 1;
        int esperado = 1;
        int obtido = mdc(p, a);

        assertEquals(esperado, obtido);
    }

    @Test
    void testMdcCasoGeral30e12() {
        int a = 30, b = 12;
        int esperado = 6;
        int obtido = mdc(a, b);

        assertEquals(esperado, obtido);
    }

    @Test
    void testMdcCasoGeral12e9() {
        int a = 12, b = 9;
        int esperado = 3;
        int obtido = mdc(a, b);

        assertEquals(esperado, obtido);
    }

    @Test
    void testMdcP4() {
        int m = 2, a = 6, b = 3;
        /* 
        mdc(2*6, 2*3) = 2 * mdc(6, 3)
        6 = 6
        */

        int esperado = 6;
        int obtido = m * mdc(a, b);

        assertEquals(mdc(m*a, m*b), obtido);
        assertEquals(esperado, obtido);
    }

    @Test
    void testMdcP9() {
        int a = 6, b = 3, c = 2;
        int esperado = 3;
        int obtido = mdc(a, b);

        assertTrue(mdc(a, mdc(b, c)) == mdc(mdc(a, b), c) && mdc(mdc(a, b), c) == mdc(a, b, c));
    }

    @Test
    void testMdc3Valores() {
        int a = 12, b = 6, c = 4;
        int esperado = 2;
        int obtido = mdc(a, b, c);

        assertEquals(esperado, obtido);
    }

    @Test
    void testMdc3NenhumValor() {
       var exception = assertThrows(IllegalArgumentException.class, MathUtil::mdc);
    }

    @Test
    void testMdcNull() {
        var exception = assertThrows(NullPointerException.class, () -> mdc(null));
        var msgEsperado = "É necessário passar um valor diferente de nulo";
        assertEquals(msgEsperado, exception.getMessage());
     }

}

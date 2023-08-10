package com.example;

public class MathUtil {
    public static int mdc(int a, int b){
        //P7
        a = Math.abs(a);
        b = Math.abs(b);

        int maior = Math.max(a, b);
        b = Math.min(a, b);
        a = maior;

        //P1
        if(b > 0 && a % b == 0)
            return b;

        if(b == 0)
            return Math.abs(a);

        return mdc(a-b, b);
    }

    public static int mdc(int ...valores){
        if(valores == null)
            throw new NullPointerException("É necessário passar um valor diferente de nulo");

        if(valores.length == 0)
            throw new IllegalArgumentException("É necessário ao menos um valor para calcular o MDC.");

        int a = valores[0];
        for (int b : valores) {
            a = mdc(a, b);
        }

        return a;
    }
}

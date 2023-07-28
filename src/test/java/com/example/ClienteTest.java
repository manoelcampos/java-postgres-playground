package com.example;

import static org.junit.jupiter.api.Assertions.assertEquals;

import org.junit.jupiter.api.Test;

public class ClienteTest {
    @Test
    void testGetIdade() {
        var cliente = new Cliente();
        assertEquals( 42, cliente.idade());
    }
}

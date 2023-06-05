package com.example;

import java.sql.DriverManager;
import java.sql.SQLException;

public class App {
    
    public static void main(String[] args){
        System.out.println();
        System.out.println("Aplicação Java de Exemplo\n");
        listarEstados();
    }

    public static void listarEstados()  {
        System.out.println("Listando estados cadastrados no banco de dados");
        try {
            Class.forName("org.postgresql.Driver");
            try(var conn = DriverManager.getConnection("jdbc:postgresql://localhost/meubanco", "postgres", "")){
                var stm = conn.createStatement();
                var result = stm.executeQuery("select * from estado");
                while(result.next()) {
                    System.out.println(result.getString("nome"));
                }
            }
        } catch (ClassNotFoundException | SQLException e) {
            System.out.println("Erro: " + e.getMessage());
        }
    }
    
}

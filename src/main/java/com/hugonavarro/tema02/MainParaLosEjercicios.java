package com.hugonavarro.tema02;

import java.sql.*;
import java.util.Scanner;

public class MainParaLosEjercicios {
    static void main() {
        Scanner sc = new Scanner(System.in);
        int opcion;

        do {
            IO.println("\n================");
            IO.println("VUELTA ATLÁNTICA");
            IO.println("================");
            IO.println("\nOPCIONES A ELEGIR:");
            IO.println("\n1. Listar equipos");
            IO.println("0. Salir");
            IO.println("-----------------");
            IO.print("Seleccione una opción: ");

            opcion = sc.nextInt();

            switch (opcion) {
                case 1:
                    listarEquipos();
                    break;
                case 0:
                    IO.println("\nSaliendo...");
                    break;
                default:
                    IO.println("\nOpción no válida.");
                    break;
            }
        } while (opcion != 0);

        sc.close();
    }

    // Ejercicio 1

    private static void listarEquipos() {
        String sql = "SELECT * FROM equipos";

        try (
                Connection conn = Conexion.getConnection();
                PreparedStatement stmt = conn.prepareStatement(sql);
                ResultSet rs = stmt.executeQuery()
        ) {
            IO.println("\n==================");
            IO.println("LISTADO DE EQUIPOS");
            IO.println("==================");

            System.out.printf("\n%-10s %-35s %-20s%n", "ID", "NOMBRE", "PAÍS");

            IO.println("------------------------------------------------------------");

            boolean hayEquipos = false;

            while (rs.next()) {
                hayEquipos = true;

                int id = rs.getInt("id_equipo");
                String nombre = rs.getString("nombre");
                String pais = rs.getString("pais");

                System.out.printf("%-10s %-35s %-20s%n", id, nombre, pais);
            }

            if (!hayEquipos) {
                IO.println("No hay equipos registrados.");
            }

            IO.println("------------------------------------------------------------");
        } catch (SQLException sqle) {
            IO.println("Error al consultar los equipos.");
            IO.println(sqle.getMessage());
        }
    }
}

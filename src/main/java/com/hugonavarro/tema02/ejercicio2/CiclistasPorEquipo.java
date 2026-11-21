package com.hugonavarro.tema02.ejercicio2;

import com.hugonavarro.tema02.Conexion;
import com.hugonavarro.tema02.ejercicio1.ListarEquipos;

import java.sql.*;
import java.util.Scanner;

public class CiclistasPorEquipo {
    public static void ciclistasPorEquipo() {
        Scanner sc = new Scanner(System.in);
        ListarEquipos.listarEquipos();

        IO.println("\n====================");
        IO.println("CICLISTAS POR EQUIPO");
        IO.println("====================");

        IO.println("\nIntroduzca el ID del equipo.");
        IO.println("Introduzca \"0\" para mostrar todos los ciclistas.");
        IO.print("ID del equipo: ");

        String entrada = sc.nextLine().trim();
        int idEquipo;

        try {
            idEquipo = Integer.parseInt(entrada);

            if (idEquipo < 0) {
                IO.println("\nEl ID del equipo no puede ser negativo.");
                return;
            }
        } catch (NumberFormatException nfe) {
            IO.println("\nSe debe introducir un número entero válido.");
            return;
        }

        String sql = """
                SELECT
                    c.id_ciclista,
                    c.nombre,
                    c.pais,
                    e.nombre AS equipo
                FROM ciclistas c
                INNER JOIN equipos e
                    ON c.id_equipo = e.id_equipo
                WHERE (? = 0 OR c.id_equipo = ?)
                ORDER BY e.nombre, c.nombre
                """;

        try (
                Connection conn = Conexion.getConnection();
                PreparedStatement stmt = conn.prepareStatement(sql)
        ) {
            stmt.setInt(1, idEquipo);
            stmt.setInt(2, idEquipo);

            try (ResultSet rs = stmt.executeQuery()) {
                IO.println("\n====================");
                IO.println("LISTADO DE CICLISTAS");
                IO.println("====================");

                System.out.printf("\n%-12s %-30s %-12s %-30s%n", "ID", "CICLISTA", "PAÍS", "EQUIPO");

                IO.println("------------------------------------------------------------------------------------------");

                boolean hayCiclistas = false;

                while (rs.next()) {
                    hayCiclistas = true;

                    int idCiclista = rs.getInt("id_ciclista");
                    String nombre = rs.getString("nombre");
                    String pais = rs.getString("pais");
                    String equipo = rs.getString("equipo");

                    System.out.printf("%-12d %-30s %-12s %-30s%n", idCiclista, nombre, pais, equipo);
                }

                if (!hayCiclistas) {
                    IO.println("No se encontraron ciclistas para el equipo indicado.");
                }

                IO.println("------------------------------------------------------------------------------------------");
            }
        } catch (SQLException sqle) {
            IO.println("\nError al consultar los ciclistas.");
            IO.println(sqle.getMessage());
        }
    }
}

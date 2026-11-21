package com.hugonavarro.tema02.ejercicio5;

import com.hugonavarro.tema02.Conexion;
import com.hugonavarro.tema02.ejercicio1.ListarEquipos;

import java.sql.*;
import java.util.Scanner;

public class ClasificacionEtapa {
    public static void clasificacionEtapa() {
        Scanner sc = new Scanner(System.in);
        ListarEquipos.listarEquipos();

        IO.println("\n==========================");
        IO.println("CLASIFICACIÓN DE UNA ETAPA");
        IO.println("==========================");

        IO.print("\nIntroduzca el ID de la etapa: ");

        String entrada = sc.nextLine().trim();
        int idEtapa;

        try {
            idEtapa = Integer.parseInt(entrada);

            if (idEtapa <= 0) {
                IO.println("\nEl ID de la etapa debe ser mayor que 0.");
                return;
            }
        } catch (NumberFormatException nfe) {
            IO.println("\nSe debe introducir un número entero válido.");
            return;
        }

        String sql = """
                SELECT
                    re.posicion,
                    c.nombre AS ciclista,
                    e.nombre AS equipo,
                    re.tiempo
                FROM resultados_etapa re
                INNER JOIN ciclistas c
                    ON re.id_ciclista = c.id_ciclista
                INNER JOIN equipos e
                    ON c.id_equipo = e.id_equipo
                WHERE re.id_etapa = ?
                    AND re.estado = 'FINALIZADO'
                ORDER BY re.tiempo ASC, re.posicion ASC
                """;

        try (
                Connection conn = Conexion.getConnection();
                PreparedStatement stmt = conn.prepareStatement(sql)
        ) {
            stmt.setInt(1, idEtapa);

            try (ResultSet rs = stmt.executeQuery()) {
                IO.println("\n=============");
                IO.println("CLASIFICACIÓN");
                IO.println("=============");

                System.out.printf("\n%-10s %-30s %-30s %-15s%n", "POSICIÓN", "CICLISTA", "EQUIPO", "TIEMPO");

                IO.println("------------------------------------------------------------------------------------------");

                boolean hayResultados = false;

                while (rs.next()) {
                    hayResultados = true;

                    int posicion = rs.getInt("posicion");
                    String ciclista = rs.getString("ciclista");
                    String equipo = rs.getString("equipo");
                    String tiempo = rs.getString("tiempo");

                    System.out.printf("%-10d %-30s %-30s %-15s%n", posicion, ciclista, equipo, tiempo);
                }

                if (!hayResultados) {
                    IO.println("No se encontraron resultados para la etapa indicada.");
                }

                IO.println("------------------------------------------------------------------------------------------");
            }
        } catch (SQLException sqle) {
            IO.println("\nError al consultar la clasificación de la etapa.");
            IO.println(sqle.getMessage());
        }
    }
}

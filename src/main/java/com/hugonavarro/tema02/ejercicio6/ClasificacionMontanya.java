package com.hugonavarro.tema02.ejercicio6;

import com.hugonavarro.tema02.Conexion;

import java.sql.*;

public class ClasificacionMontanya {
    public static void clasificacionMontanya() {
        String sql = """
                SELECT
                    c.id_ciclista,
                    c.nombre AS ciclista,
                    e.nombre AS equipo,
                    SUM(rp.puntos) AS puntos_totales
                FROM resultados_puerto rp
                INNER JOIN ciclistas c
                    ON rp.id_ciclista = c.id_ciclista
                INNER JOIN equipos e
                    ON c.id_equipo = e.id_equipo
                GROUP BY
                    c.id_ciclista,
                    c.nombre,
                    e.nombre
                ORDER BY
                    puntos_totales DESC,
                    c.nombre ASC
                """;

        try (
                Connection conn = Conexion.getConnection();
                PreparedStatement stmt = conn.prepareStatement(sql);
                ResultSet rs = stmt.executeQuery()
        ) {
            IO.println("\n===========================");
            IO.println("CLASIFICACIÓN DE LA MONTAÑA");
            IO.println("   (MAILLOT DE LUNARES)");
            IO.println("===========================");

            System.out.printf("\n%-10s %-30s %-30s %-15s%n", "POSICIÓN", "CICLISTA", "EQUIPO", "PUNTOS");

            IO.println("------------------------------------------------------------------------------------------");

            boolean hayResultados = false;
            int posicion = 1;

            while (rs.next()) {
                hayResultados = true;

                String ciclista = rs.getString("ciclista");
                String equipo = rs.getString("equipo");
                int puntos = rs.getInt("puntos_totales");

                System.out.printf("%-10d %-30s %-30s %-15d%n", posicion, ciclista, equipo, puntos);

                posicion++;
            }

            if (!hayResultados) {
                IO.println("No hay puntos de montaña registrados.");
            }

            IO.println("------------------------------------------------------------------------------------------");
        } catch (SQLException sqle) {
            IO.println("\nError al consultar la clasificación de la montaña.");
            IO.println(sqle.getMessage());
        }
    }
}

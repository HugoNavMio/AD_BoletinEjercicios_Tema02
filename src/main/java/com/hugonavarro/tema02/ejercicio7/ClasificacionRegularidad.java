package com.hugonavarro.tema02.ejercicio7;

import com.hugonavarro.tema02.Conexion;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

public class ClasificacionRegularidad {
    public static void clasificacionRegularidad() {
        String sql = """
                WITH todos_los_puntos AS (
                    SELECT
                        id_ciclista,
                        puntos
                    FROM puntos_meta
                    UNION ALL
                    SELECT
                        id_ciclista,
                        puntos
                    FROM resultados_sprint
                ),
                puntos_por_ciclista AS (
                    SELECT
                        id_ciclista,
                        SUM(puntos) AS puntos_totales
                    FROM todos_los_puntos
                    GROUP BY id_ciclista
                )
                SELECT
                    c.id_ciclista,
                    c.nombre AS ciclista,
                    e.nombre AS equipo,
                    ppc.puntos_totales
                FROM puntos_por_ciclista ppc
                INNER JOIN ciclistas c
                    ON ppc.id_ciclista = c.id_ciclista
                INNER JOIN equipos e
                    ON c.id_equipo = e.id_equipo
                ORDER BY
                    puntos_totales DESC,
                    c.nombre ASC
                """;

        try (
                Connection conn = Conexion.getConnection();
                PreparedStatement stmt = conn.prepareStatement(sql);
                ResultSet rs = stmt.executeQuery()
        ) {
            IO.println("\n===============================");
            IO.println("CLASIFICACIÓN DE LA REGULARIDAD");
            IO.println("        (MAILLOT VERDE)");
            IO.println("===============================");

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
                IO.println("No hay puntos de regularidad registrados.");
            }

            IO.println("------------------------------------------------------------------------------------------");
        } catch (SQLException sqle) {
            IO.println("\nError al consultar la clasificación de la regularidad.");
            IO.println(sqle.getMessage());
        }
    }
}

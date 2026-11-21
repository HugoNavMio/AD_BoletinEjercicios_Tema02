package com.hugonavarro.tema02.ejercicio4;

import com.hugonavarro.tema02.Conexion;

import java.sql.*;

public class MostrarCiclistasDeUnEquipo {
    public static void mostrarCiclistasDeUnEquipo(int idEquipo) {
        String sql = """
                SELECT
                    id_ciclista,
                    nombre,
                    pais
                FROM ciclistas
                WHERE id_equipo = ?
                ORDER BY nombre
                """;

        try (
                Connection conn = Conexion.getConnection();
                PreparedStatement stmt = conn.prepareStatement(sql);
        ) {
            stmt.setInt(1, idEquipo);

            try (ResultSet rs = stmt.executeQuery()) {
                IO.println("\n====================");
                IO.println("CICLISTAS DEL EQUIPO");
                IO.println("====================");

                System.out.printf("\n%-12s %-30s %-12s%n", "ID", "CICLISTA", "PAÍS");

                IO.println("------------------------------------------------------------");

                boolean hayCiclistas = false;

                while (rs.next()) {
                    hayCiclistas = true;

                    int idCiclista = rs.getInt("id_ciclista");
                    String nombre = rs.getString("nombre");
                    String pais = rs.getString("pais");

                    System.out.printf("%-12d %-30s %-12s%n", idCiclista, nombre, pais);
                }

                if (!hayCiclistas) {
                    IO.println("No hay ciclistas registrados en este equipo.");
                }

                IO.println("------------------------------------------------------------");
            }
        } catch (SQLException sqle) {
            IO.println("\nError al consultar los ciclistas.");
            IO.println(sqle.getMessage());
        }
    }
}

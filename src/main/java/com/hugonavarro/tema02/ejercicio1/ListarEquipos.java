package com.hugonavarro.tema02.ejercicio1;

import com.hugonavarro.tema02.Conexion;

import java.sql.*;

public class ListarEquipos {
    public static void listarEquipos() {
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
            IO.println("\nError al consultar los equipos.");
            IO.println(sqle.getMessage());
        }
    }
}

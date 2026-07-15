package services

import (
	"context"
	"log"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/kopdar/backend/internal/models"
	"github.com/kopdar/backend/internal/repository"
)

// SeedInsuranceProducts seeds the 4 default insurance products if they don't exist yet.
func SeedInsuranceProducts(ctx context.Context, pool *pgxpool.Pool) {
	repo := repository.NewInsuranceRepository(pool)

	products := []models.InsuranceProduct{
		{
			Name:        "Kecelakaan Kerja",
			Description: "Perlindungan untuk driver saat bekerja. Cover biaya rumah sakit akibat kecelakaan saat mengemudi atau menunggu order.",
			ProductType: models.InsuranceTypeAccident,
			Icon:        "🚑",
			CoverageDetails: map[string]interface{}{
				"coverage": []string{
					"Biaya rumah sakit akibat kecelakaan kerja hingga Rp 10.000.000",
					"Santunan harian rawat inap Rp 100.000/hari (maks 30 hari)",
					"Biaya rawat jalan akibat kecelakaan hingga Rp 2.000.000",
				},
				"exclusions": []string{
					"Kecelakaan di luar jam kerja",
					"Cedera akibat kelalaian sendiri (tidak helm, mabuk)",
					"Kondisi kesehatan yang sudah ada sebelumnya",
				},
			},
			PriceMember:    25000,
			PriceNonMember: 35000,
			PartnerName:    "Mitra Proteksi",
			Status:         "active",
		},
		{
			Name:        "Rawat Inap",
			Description: "Santunan uang tunai saat dirawat di rumah sakit. Cair langsung ke rekening driver, bisa dipakai untuk biaya hidup selama tidak bisa narik.",
			ProductType: models.InsuranceTypeInpatient,
			Icon:        "🏥",
			CoverageDetails: map[string]interface{}{
				"coverage": []string{
					"Santunan rawat inap Rp 200.000/hari (maks 60 hari per tahun)",
					"Santunan ICU Rp 400.000/hari (maks 15 hari)",
					"Santunan meninggal dunia Rp 5.000.000",
				},
				"exclusions": []string{
					"Rawat inap akibat penyakit yang sudah ada sebelumnya (pre-existing)",
					"Rawat inap kurang dari 24 jam (kecuali ICU)",
					"Prosedur kosmetik atau operasi elektif",
				},
			},
			PriceMember:    85000,
			PriceNonMember: 120000,
			PartnerName:    "Sehat Bersama",
			Status:         "active",
		},
		{
			Name:        "Kendaraan",
			Description: "Proteksi untuk motor driver. Cover kerusakan akibat kecelakaan, pencurian, dan bencana alam.",
			ProductType: models.InsuranceTypeVehicle,
			Icon:        "🛵",
			CoverageDetails: map[string]interface{}{
				"coverage": []string{
					"Kerusakan akibat kecelakaan hingga Rp 5.000.000",
					"Pencurian kendaraan (total loss) hingga Rp 10.000.000",
					"Kerusakan akibat bencana alam hingga Rp 3.000.000",
					"Biaya derek Rp 250.000/kejadian",
				},
				"exclusions": []string{
					"Kendaraan yang tidak memiliki STNK/SIM aktif",
					"Kerusakan akibat modifikasi ilegal",
					"Kecelakaan saat dipakai balapan",
				},
			},
			PriceMember:    45000,
			PriceNonMember: 65000,
			PartnerName:    "Aman Berkendara",
			Status:         "active",
		},
		{
			Name:        "Keluarga",
			Description: "Perlindungan menyeluruh untuk keluarga driver. Cover istri/suami dan maksimal 3 anak.",
			ProductType: models.InsuranceTypeFamily,
			Icon:        "👨‍👩‍👧",
			CoverageDetails: map[string]interface{}{
				"coverage": []string{
					"Biaya rumah sakit untuk keluarga hingga Rp 15.000.000/tahun",
					"Santunan meninggal dunia anggota keluarga Rp 10.000.000",
					"Biaya persalinan hingga Rp 3.000.000",
					"Rawat jalan anak Rp 1.500.000/tahun",
				},
				"exclusions": []string{
					"Anggota keluarga yang tidak terdaftar",
					"Penyakit kritis yang sudah didiagnosis sebelum polis aktif",
					"Perawatan di luar negeri",
				},
			},
			PriceMember:    150000,
			PriceNonMember: 200000,
			PartnerName:    "Keluarga Sejahtera",
			Status:         "active",
		},
	}

	if err := repo.SeedProducts(products); err != nil {
		log.Printf("[SEED] Gagal seed produk asuransi: %v", err)
		return
	}
	log.Println("[SEED] Produk asuransi berhasil di-seed")
}

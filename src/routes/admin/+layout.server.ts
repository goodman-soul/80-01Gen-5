import type { LayoutServerLoad } from './$types';
import { redirect } from '@sveltejs/kit';
import { createServerClient } from '@supabase/ssr';
import { PUBLIC_SUPABASE_ANON_KEY, PUBLIC_SUPABASE_URL } from '$env/static/public';

export const load: LayoutServerLoad = async ({ cookies }) => {
	const allCookies = cookies.getAll();

	const supabase = createServerClient(PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_ANON_KEY, {
		cookies: {
			getAll() {
				return allCookies;
			}
		}
	});

	const {
		data: { session }
	} = await supabase.auth.getSession();

	if (!session) {
		redirect(303, '/login');
	}

	const { data: profile } = await supabase
		.from('profiles')
		.select('id, role, institution_id, full_name')
		.eq('id', session.user.id)
		.single();

	if (!profile || profile.role !== 'admin') {
		if (profile?.role === 'parent') redirect(303, '/parent');
		if (profile?.role === 'therapist') redirect(303, '/therapist');
		redirect(303, '/');
	}

	let institution = null;
	let users = [];
	let therapists = [];
	let children = [];

	if (profile.institution_id) {
		const { data: instData } = await supabase
			.from('institutions')
			.select('*')
			.eq('id', profile.institution_id)
			.single();
		institution = instData;

		const { data: usersData } = await supabase
			.from('profiles')
			.select('*')
			.eq('institution_id', profile.institution_id)
			.order('created_at', { ascending: false });
		users = usersData || [];

		therapists = users.filter((u) => u.role === 'therapist');

		const therapistIds = therapists.map((t) => t.id);
		if (therapistIds.length > 0) {
			const { data: childrenData } = await supabase
				.from('children')
				.select('*, parent:profiles(full_name, phone)')
				.in('therapist_id', therapistIds)
				.order('created_at', { ascending: false });
			children = childrenData || [];
		}
	}

	return { profile, institution, users, therapists, children };
};

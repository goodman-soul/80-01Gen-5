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
		.select('role')
		.eq('id', session.user.id)
		.single();

	if (!profile || profile.role !== 'parent') {
		if (profile?.role === 'therapist') redirect(303, '/therapist');
		if (profile?.role === 'admin') redirect(303, '/admin');
		redirect(303, '/');
	}

	const { data: children } = await supabase
		.from('children')
		.select('*')
		.eq('parent_id', session.user.id)
		.order('created_at', { ascending: false });

	return { profile, children: children || [] };
};
